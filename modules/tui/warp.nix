{ config, pkgs, lib, ... }:
let
  cfg = config.my.features.home;
  warpWrapped = pkgs.symlinkJoin {
    name = "warp-terminal-wrapped";
    paths = [ pkgs.warp-terminal ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      if [ -x "$out/bin/warp-terminal" ]; then
        # Warp's main binary is patched by nixpkgs, but it still dlopens
        # libcurl at runtime. Keep the graphics stack and libcurl discoverable
        # through LD_LIBRARY_PATH so startup does not crash.
        wrapProgram $out/bin/warp-terminal \
          --set __EGL_VENDOR_LIBRARY_DIRS ${pkgs.mesa}/share/glvnd/egl_vendor.d \
          --set LIBGL_DRIVERS_PATH ${pkgs.mesa}/lib/dri \
          --set-default GDK_BACKEND x11 \
          --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [
            pkgs.mesa
            pkgs.libglvnd
            pkgs.curl
          ]}
      fi

      cat > $out/bin/warp-safe <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

unset GTK_IM_MODULE
unset XMODIFIERS
export GDK_BACKEND=x11

exec "$(dirname "$0")/warp-terminal" "$@"
EOF
      chmod +x $out/bin/warp-safe
    '';
  };
in
{
  options.my.features.home.warp = lib.mkEnableOption "Enable Warp terminal module";

  config = lib.mkIf cfg.warp {
    home.packages = [ warpWrapped ];
  };
}
