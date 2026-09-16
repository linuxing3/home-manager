{
  config,
  lib,
  pkgs,
  ...
}: let
  stylixTheme = pkgs.writeShellApplication {
    name = "stylix-theme";
    runtimeInputs = with pkgs; [dconf feh glib gsettings-desktop-schemas];
    text = ''
      set -euo pipefail

      export DISPLAY="''${DISPLAY:-:0}"
      export LC_ALL=C
      export GSETTINGS_SCHEMA_DIR=${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}/glib-2.0/schemas
      if [[ -z "''${XAUTHORITY:-}" && -f "$HOME/.Xauthority" ]]; then
        export XAUTHORITY="$HOME/.Xauthority"
      fi

      feh --no-fehbg --bg-fill ${config.stylix.image} || true
      gsettings set org.gnome.desktop.interface color-scheme prefer-dark || true
      gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-dark || true
      gsettings set org.gnome.desktop.interface icon-theme Yaru-purple || true

      echo "stylix theme: omarchy-catppuccin-dark"
    '';
  };
in {
  environment.systemPackages = [stylixTheme pkgs.adw-gtk3 pkgs.yaru-theme];

  services.xserver.displayManager.startx.extraCommands = lib.mkAfter ''
    ${lib.getExe stylixTheme} || true
  '';
}
