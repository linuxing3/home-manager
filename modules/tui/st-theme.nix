{
  lib,
  pkgs,
  userSettings,
  ...
}: let
  themeDir = ../../themes + "/${userSettings.theme}";
  palette = import (themeDir + "/palette.nix");
  color = name: "#${palette.${name}}";

  # ── Catppuccin Mocha (dark) ────────────────────────────────────────────
  darkTheme = pkgs.writeText "st-catppuccin-mocha.Xresources" ''
    st.foreground: ${color "text"}
    st.background: ${color "background"}
    st.cursorColor: ${color "rosewater"}

    st.color0:  ${color "surface1"}
    st.color1:  ${color "red"}
    st.color2:  ${color "green"}
    st.color3:  ${color "yellow"}
    st.color4:  ${color "blue"}
    st.color5:  ${color "pink"}
    st.color6:  ${color "teal"}
    st.color7:  ${color "subtext1"}
    st.color8:  ${color "surface2"}
    st.color9:  ${color "red"}
    st.color10: ${color "green"}
    st.color11: ${color "yellow"}
    st.color12: ${color "blue"}
    st.color13: ${color "pink"}
    st.color14: ${color "teal"}
    st.color15: ${color "subtext0"}
  '';

  # ── Catppuccin Latte (light) ───────────────────────────────────────────
  lightTheme = pkgs.writeText "st-catppuccin-latte.Xresources" ''
    st.foreground: #4c4f69
    st.background: #eff1f5
    st.cursorColor: #dc8a78

    st.color0:  #bcc0cc
    st.color1:  #d20f39
    st.color2:  #40a02b
    st.color3:  #df8e1d
    st.color4:  #1e66f5
    st.color5:  #ea76cb
    st.color6:  #179299
    st.color7:  #5c5f77
    st.color8:  #acb0be
    st.color9:  #d20f39
    st.color10: #40a02b
    st.color11: #df8e1d
    st.color12: #1e66f5
    st.color13: #ea76cb
    st.color14: #179299
    st.color15: #6c6f85
  '';

  # ── fzf sourceable theme files ──────────────────────────────────────────
  fzfOpts = colors: ''export FZF_DEFAULT_OPTS="${colors} --border=rounded --border-label= --preview-window=border-rounded --prompt=> --marker=> --pointer=> --separator=─ --scrollbar=│ --info=right"'';
  fzfDarkFile = pkgs.writeText "fzf-dark.sh" (fzfOpts "--color=fg:#cdd6f4,fg+:#cdd6f4,bg:#010101,bg+:#313244 --color=hl:#f5c2e7,hl+:#f5c2e7,info:#89b4fa,marker:#a6e3a1 --color=prompt:#89b4fa,spinner:#94e2d5,pointer:#f5c2e7,header:#b4befe --color=border:#45475a,label:#cdd6f4,query:#cdd6f4");
  fzfLightFile = pkgs.writeText "fzf-light.sh" (fzfOpts "--color=fg:#4c4f69,fg+:#4c4f69,bg:#eff1f5,bg+:#ccd0da --color=hl:#ea76cb,hl+:#ea76cb,info:#1e66f5,marker:#40a02b --color=prompt:#1e66f5,spinner:#179299,pointer:#ea76cb,header:#7287fd --color=border:#bcc0cc,label:#4c4f69,query:#4c4f69");

  # ── SIGUSR1 helper for patched st ──────────────────────────────────────
  signalSt = ''
    st_bin="$(${pkgs.coreutils}/bin/readlink -f ${pkgs.st-xyz}/bin/st)"
    for pid in $(${pkgs.procps}/bin/pgrep -x st || true); do
      exe="$(${pkgs.coreutils}/bin/readlink -f "/proc/$pid/exe" || true)"
      if [[ "$exe" == "$st_bin" ]]; then
        ${pkgs.procps}/bin/kill -USR1 "$pid" || true
      fi
    done
  '';

  # ── Ghostty theme files ────────────────────────────────────────────────
  ghosttyDarkTheme = pkgs.writeText "ghostty-catppuccin-mocha" ''
    palette = 0=#45475a
    palette = 1=#f38ba8
    palette = 2=#a6e3a1
    palette = 3=#f9e2af
    palette = 4=#89b4fa
    palette = 5=#f5c2e7
    palette = 6=#94e2d5
    palette = 7=#bac2de
    palette = 8=#585b70
    palette = 9=#f38ba8
    palette = 10=#a6e3a1
    palette = 11=#f9e2af
    palette = 12=#89b4fa
    palette = 13=#f5c2e7
    palette = 14=#94e2d5
    palette = 15=#a6adc8
    background = 1e1e2e
    foreground = cdd6f4
    cursor-color = f5e0dc
    selection-background = 585b70
    selection-foreground = cdd6f4
  '';

  ghosttyLightTheme = pkgs.writeText "ghostty-catppuccin-latte" ''
    palette = 0=#bcc0cc
    palette = 1=#d20f39
    palette = 2=#40a02b
    palette = 3=#df8e1d
    palette = 4=#1e66f5
    palette = 5=#ea76cb
    palette = 6=#179299
    palette = 7=#5c5f77
    palette = 8=#acb0be
    palette = 9=#d20f39
    palette = 10=#40a02b
    palette = 11=#df8e1d
    palette = 12=#1e66f5
    palette = 13=#ea76cb
    palette = 14=#179299
    palette = 15=#6c6f85
    background = eff1f5
    foreground = 4c4f69
    cursor-color = dc8a78
    selection-background = acb0be
    selection-foreground = 4c4f69
  '';

  # ── Kitty theme files (compatible with `kitty @ set-colors`) ───────────
  kittyDarkTheme = pkgs.writeText "kitty-catppuccin-mocha.conf" ''
    foreground #cdd6f4
    background #1e1e2e
    cursor #f5e0dc
    selection_foreground #cdd6f4
    selection_background #585b70
    color0 #45475a
    color1 #f38ba8
    color2 #a6e3a1
    color3 #f9e2af
    color4 #89b4fa
    color5 #f5c2e7
    color6 #94e2d5
    color7 #bac2de
    color8 #585b70
    color9 #f38ba8
    color10 #a6e3a1
    color11 #f9e2af
    color12 #89b4fa
    color13 #f5c2e7
    color14 #94e2d5
    color15 #a6adc8
  '';

  kittyLightTheme = pkgs.writeText "kitty-catppuccin-latte.conf" ''
    foreground #4c4f69
    background #eff1f5
    cursor #dc8a78
    selection_foreground #4c4f69
    selection_background #acb0be
    color0 #bcc0cc
    color1 #d20f39
    color2 #40a02b
    color3 #df8e1d
    color4 #1e66f5
    color5 #ea76cb
    color6 #179299
    color7 #5c5f77
    color8 #acb0be
    color9 #d20f39
    color10 #40a02b
    color11 #df8e1d
    color12 #1e66f5
    color13 #ea76cb
    color14 #179299
    color15 #6c6f85
  '';

  # ── Main theme-switch script ───────────────────────────────────────────
  themeSwitch = pkgs.writeShellScriptBin "theme-switch" ''
    set -euo pipefail

    export DISPLAY="''${DISPLAY:-:0}"
    export LC_ALL=C
    if [[ -z "''${XAUTHORITY:-}" && -f "$HOME/.Xauthority" ]]; then
      export XAUTHORITY="$HOME/.Xauthority"
    fi

    state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}"
    state_file="$state_dir/theme-mode"
    fzf_file="$state_dir/fzf-theme.sh"
    ${pkgs.coreutils}/bin/mkdir -p "$state_dir"

    apply() {
      local mode="$1"

      # ── 1. st terminal (xrdb + SIGUSR1) ──────────────────────────────
      case "$mode" in
        dark)  ${pkgs.xrdb}/bin/xrdb -merge ${darkTheme} ;;
        light) ${pkgs.xrdb}/bin/xrdb -merge ${lightTheme} ;;
        *) echo "unknown mode: $mode" >&2; exit 1 ;;
      esac
      ${signalSt}

      # ── 2. GTK / GNOME / browsers ────────────────────────────────────
      export GSETTINGS_SCHEMA_DIR=${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}/glib-2.0/schemas
      case "$mode" in
        dark)
          ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface color-scheme prefer-dark  || true
          ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-dark    || true
          ;;
        light)
          ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface color-scheme prefer-light  || true
          ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3          || true
          ;;
      esac

      # ── 3. Helix (sed config -> auto-reloads) ─────────────────────────
      helix_config="''${XDG_CONFIG_HOME:-$HOME/.config}/helix/config.toml"
      if [[ -f "$helix_config" ]]; then
        case "$mode" in
          dark)  ${pkgs.gnused}/bin/sed -i 's/^theme = .*/theme = "catppuccin_mocha"/' "$helix_config" ;;
          light) ${pkgs.gnused}/bin/sed -i 's/^theme = .*/theme = "catppuccin_latte"/' "$helix_config" ;;
        esac
      fi

      # ── 4. fzf (sourceable file for new shells) ──────────────────────
      case "$mode" in
        dark)  ${pkgs.coreutils}/bin/install -m 644 ${fzfDarkFile} "$fzf_file" ;;
        light) ${pkgs.coreutils}/bin/install -m 644 ${fzfLightFile} "$fzf_file" ;;
      esac

      # ── 5. Write state (nvim watches this file) ──────────────────────
      printf '%s\n' "$mode" >"$state_file"

      # ── 6. Ghostty (runtime config override + SIGUSR1 reload) ────────
      ghostty_conf="$state_dir/ghostty-theme.conf"
      case "$mode" in
        dark)  printf '%s\n' 'theme = "Catppuccin Mocha"' >"$ghostty_conf" ;;
        light) printf '%s\n' 'theme = "Catppuccin Latte"' >"$ghostty_conf" ;;
      esac
      for pid in $(${pkgs.procps}/bin/pgrep -x ghostty || true); do
        ${pkgs.procps}/bin/kill -USR1 "$pid" || true
      done
      for pid in $(${pkgs.procps}/bin/pgrep -x .ghostty-wrapp || true); do
        ${pkgs.procps}/bin/kill -USR1 "$pid" || true
      done

      # ── 7. Kitty (remote control set-colors) ─────────────────────────
      if command -v ${pkgs.kitty}/bin/kitty >/dev/null 2>&1; then
        case "$mode" in
          dark)  kitty_theme="${kittyDarkTheme}" ;;
          light) kitty_theme="${kittyLightTheme}" ;;
        esac
        for sock in /tmp/kitty-sock-*; do
          [[ -S "$sock" ]] && ${pkgs.kitty}/bin/kitty @ --to "unix:$sock" set-colors "$kitty_theme" 2>/dev/null || true
        done
        ${pkgs.kitty}/bin/kitty @ set-colors --all "$kitty_theme" 2>/dev/null || true
      fi
      kitty_conf="''${XDG_STATE_HOME:-$HOME/.local/state}/kitty-theme.conf"
      case "$mode" in
        dark)  ${pkgs.coreutils}/bin/install -m 644 ${kittyDarkTheme} "$kitty_conf" ;;
        light) ${pkgs.coreutils}/bin/install -m 644 ${kittyLightTheme} "$kitty_conf" ;;
      esac

      echo "theme: catppuccin $mode"
    }

    case "''${1:-auto}" in
      dark|light)
        apply "$1"
        ;;
      auto)
        hour=$(date +%H | sed 's/^0*//')
        : "''${hour:=0}"
        if (( hour >= 7 && hour < 18 )); then
          apply light
        else
          apply dark
        fi
        ;;
      toggle)
        if [[ -f "$state_file" ]]; then
          current=$(cat "$state_file")
        else
          current=dark
        fi
        case "$current" in
          dark) apply light ;;
          *)    apply dark ;;
        esac
        ;;
      status)
        if [[ -f "$state_file" ]]; then
          cat "$state_file"
        else
          echo unknown
        fi
        ;;
      *)
        echo "usage: theme-switch [auto|dark|light|toggle|status]" >&2
        exit 1
        ;;
    esac
  '';

  # ── Backward-compatible st-theme wrapper ───────────────────────────────
  stTheme = pkgs.writeShellScriptBin "st-theme" ''
    exec ${themeSwitch}/bin/theme-switch "$@"
  '';
in {
  fonts.fontconfig.enable = true;

  home.packages = [themeSwitch stTheme pkgs.nerd-fonts.jetbrains-mono pkgs.dconf];

  home.file.".Xdefaults".text = ''
    Xft.dpi: 96
    Xft.antialias: true
    Xft.hinting: true
    Xft.hintstyle: hintfull
    Xft.rgba: rgb
    Xft.lcdfilter: lcddefault
    st.font: JetBrainsMono Nerd Font:pixelsize=16:antialias=true:autohint=true
    st.fontalt0: JetBrainsMono Nerd Font:pixelsize=16:antialias=true:autohint=true
    st.alpha: 0.4
  '';

  home.file.".xsessionrc".text = ''
    ${pkgs.xrdb}/bin/xrdb -merge "$HOME/.Xdefaults"
    ${themeSwitch}/bin/theme-switch auto
  '';

  xdg.configFile."st/catppuccin-mocha.Xresources".source = darkTheme;
  xdg.configFile."st/catppuccin-latte.Xresources".source = lightTheme;

  xdg.configFile."autostart/theme-switch.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Catppuccin theme auto switch
    Exec=${themeSwitch}/bin/theme-switch auto
    X-GNOME-Autostart-enabled=true
  '';

  systemd.user.services.theme-auto = {
    Unit.Description = "Apply Catppuccin light/dark theme based on time of day";
    Service = {
      Type = "oneshot";
      ExecStart = "${themeSwitch}/bin/theme-switch auto";
      Environment = [
        "DISPLAY=:0"
      ];
    };
  };

  systemd.user.timers.theme-auto = {
    Unit.Description = "Switch Catppuccin theme at 07:00 and 18:00";
    Timer = {
      OnCalendar = ["*-*-* 07:00:00" "*-*-* 18:00:00"];
      Persistent = true;
    };
    Install.WantedBy = ["timers.target" "default.target"];
  };

  home.activation.applyThemeSwitch = lib.hm.dag.entryAfter ["linkGeneration"] ''
    run ${themeSwitch}/bin/theme-switch auto || true
  '';
}
