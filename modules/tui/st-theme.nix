{
  lib,
  pkgs,
  userSettings,
  ...
}: let
  themeDir = ../../themes + "/${userSettings.theme}";
  palette = import (themeDir + "/palette.nix");
  color = name: "#${palette.${name}}";

  theme = pkgs.writeText "st-omarchy-catppuccin-dark.Xresources" ''
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

  stTheme = pkgs.writeShellScriptBin "st-theme" ''
    set -euo pipefail

    export DISPLAY="''${DISPLAY:-:0}"
    export LC_ALL=C
    if [[ -z "''${XAUTHORITY:-}" && -f "$HOME/.Xauthority" ]]; then
      export XAUTHORITY="$HOME/.Xauthority"
    fi

    ${pkgs.xrdb}/bin/xrdb -merge ${theme}

    st_bin="$(${pkgs.coreutils}/bin/readlink -f ${pkgs.st-xyz}/bin/st)"
    for pid in $(${pkgs.procps}/bin/pgrep -x st || true); do
      exe="$(${pkgs.coreutils}/bin/readlink -f "/proc/$pid/exe" || true)"
      if [[ "$exe" == "$st_bin" ]]; then
        ${pkgs.procps}/bin/kill -USR1 "$pid" || true
      fi
    done

    echo "st theme: omarchy-catppuccin-dark"
  '';
in {
  fonts.fontconfig.enable = true;

  home.packages = [stTheme pkgs.nerd-fonts.jetbrains-mono];

  home.file.".Xdefaults".text = ''
    st.font: JetBrainsMono Nerd Font:pixelsize=16:antialias=true:autohint=true
    st.fontalt0: JetBrainsMono Nerd Font:pixelsize=16:antialias=true:autohint=true
    st.alpha: 0.4
  '';

  home.file.".xsessionrc".text = ''
    ${pkgs.xrdb}/bin/xrdb -merge "$HOME/.Xdefaults"
    ${stTheme}/bin/st-theme
  '';

  xdg.configFile."st/omarchy-catppuccin-dark.Xresources".source = theme;

  xdg.configFile."autostart/st-theme.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=st Omarchy Catppuccin theme
    Exec=${stTheme}/bin/st-theme
    X-GNOME-Autostart-enabled=true
  '';

  home.activation.applyStTheme = lib.hm.dag.entryAfter ["linkGeneration"] ''
    run ${stTheme}/bin/st-theme || true
  '';
}
