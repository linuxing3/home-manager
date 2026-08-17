{pkgs, ...}: let
  lightTheme = pkgs.writeText "st-gruvbox-light.Xresources" ''
    st.foreground: #3c3836
    st.background: #fbf1c7
    st.cursorColor: #3c3836

    st.color0:  #fbf1c7
    st.color1:  #cc241d
    st.color2:  #98971a
    st.color3:  #d79921
    st.color4:  #458588
    st.color5:  #b16286
    st.color6:  #689d6a
    st.color7:  #7c6f64
    st.color8:  #928374
    st.color9:  #9d0006
    st.color10: #79740e
    st.color11: #b57614
    st.color12: #076678
    st.color13: #8f3f71
    st.color14: #427b58
    st.color15: #3c3836
  '';

  darkTheme = pkgs.writeText "st-gruvbox-dark.Xresources" ''
    st.foreground: #ebdbb2
    st.background: #282828
    st.cursorColor: #ebdbb2

    st.color0:  #282828
    st.color1:  #cc241d
    st.color2:  #98971a
    st.color3:  #d79921
    st.color4:  #458588
    st.color5:  #b16286
    st.color6:  #689d6a
    st.color7:  #a89984
    st.color8:  #928374
    st.color9:  #fb4934
    st.color10: #b8bb26
    st.color11: #fabd2f
    st.color12: #83a598
    st.color13: #d3869b
    st.color14: #8ec07c
    st.color15: #ebdbb2
  '';

  stTheme = pkgs.writeShellScriptBin "st-theme" ''
    set -euo pipefail

    mode="''${1:-auto}"
    if [[ "$mode" == "auto" ]]; then
      hour="$(${pkgs.coreutils}/bin/date +%H)"
      if ((10#$hour >= 7 && 10#$hour < 18)); then
        mode="light"
      else
        mode="dark"
      fi
    fi

    state_home="''${XDG_STATE_HOME:-$HOME/.local/state}"
    state_file="$state_home/st-theme/current"

    if [[ "$mode" == "status" ]]; then
      if [[ -r "$state_file" ]]; then
        ${pkgs.coreutils}/bin/cat "$state_file"
      else
        echo "unknown"
      fi
      exit 0
    fi

    case "$mode" in
      light)
        theme_file=${lightTheme}
        ;;
      dark)
        theme_file=${darkTheme}
        ;;
      *)
        echo "Usage: st-theme [auto|light|dark|status]" >&2
        exit 2
        ;;
    esac

    export DISPLAY="''${DISPLAY:-:0}"
    export LC_ALL=C
    if [[ -z "''${XAUTHORITY:-}" && -f "$HOME/.Xauthority" ]]; then
      export XAUTHORITY="$HOME/.Xauthority"
    fi

    ${pkgs.xrdb}/bin/xrdb -merge "$theme_file"
    ${pkgs.coreutils}/bin/mkdir -p "$(${pkgs.coreutils}/bin/dirname "$state_file")"
    printf '%s\n' "$mode" >"$state_file"
    echo "st theme: $mode"
  '';
in {
  fonts.fontconfig.enable = true;

  home.packages = [
    stTheme
    pkgs.nerd-fonts.jetbrains-mono
  ];

  home.file.".Xdefaults".text = ''
    st.font: JetBrainsMono Nerd Font:pixelsize=16:antialias=true:autohint=true
    st.fontalt0: JetBrainsMono Nerd Font:pixelsize=16:antialias=true:autohint=true
    st.alpha: 1.0
  '';

  home.file.".xsessionrc".text = ''
    ${pkgs.xrdb}/bin/xrdb -merge "$HOME/.Xdefaults"
    ${stTheme}/bin/st-theme auto
  '';

  xdg.configFile."st/gruvbox-light.Xresources".source = lightTheme;
  xdg.configFile."st/gruvbox-dark.Xresources".source = darkTheme;

  systemd.user.services.st-theme-auto = {
    Unit = {
      Description = "Select the Gruvbox theme for st";
      After = ["graphical-session.target"];
    };

    Service = {
      Type = "oneshot";
      ExecStart = "${stTheme}/bin/st-theme auto";
      Environment = ["DISPLAY=:0"];
    };
  };

  systemd.user.timers.st-theme-auto = {
    Unit.Description = "Switch the st Gruvbox theme by time";

    Timer = {
      OnCalendar = [
        "*-*-* 07:00:00"
        "*-*-* 18:00:00"
      ];
      Persistent = true;
      Unit = "st-theme-auto.service";
    };

    Install.WantedBy = ["timers.target"];
  };
}
