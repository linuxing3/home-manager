{ config, inputs, pkgs, lib, ... }:
let
  cfg = config.my.features.home;
  ghosttyBase = inputs.ghostty.packages.${pkgs.system}.default;
  ghosttyWrapped = pkgs.symlinkJoin {
    name = "ghostty-wrapped";
    paths = [ ghosttyBase ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    meta.mainProgram = "ghostty";
    postBuild = ''
      # Same wrapper strategy used by wezterm module in this repo.
      wrapProgram $out/bin/ghostty \
        --set __EGL_VENDOR_LIBRARY_DIRS ${pkgs.mesa}/share/glvnd/egl_vendor.d \
        --set LIBGL_DRIVERS_PATH ${pkgs.mesa}/lib/dri \
        --set GTK_IM_MODULE none \
        --set XMODIFIERS "" \
        --set-default GDK_BACKEND x11 \
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ pkgs.mesa pkgs.libglvnd ]}

      # Launch helper: reduce noisy GTK/systemd integration on distros where
      # user-systemd lacks full ManagedOOM* options.
      cat > $out/bin/ghostty-no-systemd <<'EOF'
#!/usr/bin/env bash
unset GTK_IM_MODULE
unset XMODIFIERS
export GDK_DEBUG=no-systemd
BIN_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
exec "$BIN_DIR/ghostty" "$@"
EOF
      chmod +x $out/bin/ghostty-no-systemd

      # Launch helper (方案B): on oxwm/X11, Ghostty may crash with
      # gtk_widget_unparent assertions even with software rendering.
      # In that known-incompatible WM, fallback to wezterm/kitty.
      cat > $out/bin/ghostty-safe <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

BIN_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
REAL_GHOSTTY="$BIN_DIR/ghostty"

# Keep CLI subcommands on Ghostty itself (+version/+validate-config/etc.).
if [ "''${1:-}" != "" ] && [[ "''${1}" == +* ]]; then
  exec "$REAL_GHOSTTY" "$@"
fi

wm_name=""
if [ -n "''${DISPLAY:-}" ] && command -v xprop >/dev/null 2>&1; then
  wm_id="$(xprop -root _NET_SUPPORTING_WM_CHECK 2>/dev/null | sed -n "s/.*# \(0x[0-9a-fA-F]\+\).*/\1/p" | head -n1 || true)"
  if [ -n "$wm_id" ]; then
    wm_name="$(xprop -id "$wm_id" _NET_WM_NAME 2>/dev/null | sed -n "s/.*= \"\(.*\)\"/\1/p" | head -n1 || true)"
  fi
fi

if [ "$wm_name" = "oxwm" ]; then
  echo "[ghostty-safe] 检测到 oxwm：Ghostty(GTK4) 在该 WM 下已知会触发 gtk_widget_unparent 并秒退，自动回退到备用终端。" >&2
  if command -v wezterm >/dev/null 2>&1; then
    exec wezterm start -- "$@"
  fi
  if command -v kitty >/dev/null 2>&1; then
    exec kitty "$@"
  fi
  echo "[ghostty-safe] 未找到 wezterm/kitty，继续尝试 Ghostty（可能仍会退出）。" >&2
fi

unset GTK_IM_MODULE
unset XMODIFIERS
export GDK_DEBUG=no-systemd
export GDK_BACKEND=x11
export LIBGL_ALWAYS_SOFTWARE=1
export GALLIUM_DRIVER=llvmpipe
export MESA_LOADER_DRIVER_OVERRIDE=llvmpipe
export GSK_RENDERER=cairo
exec "$REAL_GHOSTTY" "$@"
EOF
      chmod +x $out/bin/ghostty-safe
    '';
  };
in
{
  options.my.features.home.ghostty = lib.mkEnableOption "Enable ghostty module";

  config = lib.mkIf cfg.ghostty {
    programs.ghostty = {
      enable = true;
      package = ghosttyWrapped;
      # Prefer cache hit from ghostty.cachix.org (already configured in system nix.settings);
      # if no substituter hit, Nix automatically falls back to source build.
      settings = {
        theme = "Catppuccin Mocha";
        "background-opacity" = 0.95;
        "window-padding-x" = 2;
        "window-padding-y" = 0;
        "gtk-titlebar" = false;

      };
    };

    # Force HM ownership of ghostty config path to avoid clobber when a legacy
    # file/symlink exists from manual setup.
    xdg.configFile."ghostty/config".force = true;

    # Remove optional second config file to avoid duplicate-load and empty-file
    # warnings from legacy ~/.config/ghostty/config.ghostty.
    home.activation.ghosttyRemoveLegacyConfigGhostty = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
      CFG_GHOSTTY="$HOME/.config/ghostty/config.ghostty"
      if [ -e "$CFG_GHOSTTY" ] || [ -L "$CFG_GHOSTTY" ]; then
        rm -f "$CFG_GHOSTTY"
      fi
    '';

    # Avoid clobber failure when an unmanaged ~/.config/ghostty/config already exists.
    # Keep a timestamped backup, then let HM own the target path.
    home.activation.ghosttyConfigFileBackup = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
      CFG="$HOME/.config/ghostty/config"
      if [ -e "$CFG" ] && [ ! -L "$CFG" ]; then
        mkdir -p "$HOME/.config/ghostty"
        mv "$CFG" "$CFG.pre-hm.$(date +%Y%m%d%H%M%S).bak"
      fi
    '';

    # Guard against mixed-management conflict when ghostty was previously installed with
    # `nix profile install ...` in the user profile.
    home.activation.ghosttyProfileConflictFix = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      NIX_BIN="$(command -v nix || true)"
      if [ -z "$NIX_BIN" ] && [ -x /nix/var/nix/profiles/default/bin/nix ]; then
        NIX_BIN=/nix/var/nix/profiles/default/bin/nix
      fi

      if [ -n "$NIX_BIN" ]; then
        # Best effort: remove legacy user-profile Ghostty installs that conflict with HM-managed package links.
        # Keep this POSIX-minimal (no awk dependency inside activation environment).
        $NIX_BIN profile remove --profile "$HOME/.nix-profile" ghostty >/dev/null 2>&1 || true
        $NIX_BIN profile remove --profile "$HOME/.nix-profile" nixpkgs#ghostty >/dev/null 2>&1 || true
        $NIX_BIN profile remove --profile "$HOME/.nix-profile" github:ghostty-org/ghostty >/dev/null 2>&1 || true
        $NIX_BIN profile remove --profile "$HOME/.nix-profile" github:ghostty-org/ghostty#default >/dev/null 2>&1 || true
      fi
    '';
  };
}
