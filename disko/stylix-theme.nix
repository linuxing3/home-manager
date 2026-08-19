{
  lib,
  pkgs,
  userSettings,
  ...
}: let
  themeDir = ../themes;
  darkTheme = themeDir + "/gruvbox-dark-medium";
  lightTheme = themeDir + "/gruvbox-light-medium";

  fetchWallpaper = dir:
    pkgs.fetchurl {
      url = lib.removeSuffix "\n" (builtins.readFile (dir + "/backgroundurl.txt"));
      sha256 = lib.removeSuffix "\n" (builtins.readFile (dir + "/backgroundsha256.txt"));
    };

  wallpaperDark = fetchWallpaper darkTheme;
  wallpaperLight = fetchWallpaper lightTheme;

  palettes = {
    dark = {
      base00 = "282828";
      base01 = "3c3836";
      base02 = "504945";
      base03 = "665c54";
      base04 = "bdae93";
      base05 = "d5c4a1";
      base06 = "ebdbb2";
      base07 = "fbf1c7";
      base08 = "fb4934";
      base09 = "fe8019";
      base0A = "fabd2f";
      base0B = "b8bb26";
      base0C = "8ec07c";
      base0D = "83a598";
      base0E = "d3869b";
      base0F = "d65d0e";
    };
    light = {
      base00 = "fbf1c7";
      base01 = "ebdbb2";
      base02 = "d5c4a1";
      base03 = "bdae93";
      base04 = "665c54";
      base05 = "504945";
      base06 = "3c3836";
      base07 = "282828";
      base08 = "9d0006";
      base09 = "af3a03";
      base0A = "b57614";
      base0B = "79740e";
      base0C = "427b58";
      base0D = "076678";
      base0E = "8f3f71";
      base0F = "d65d0e";
    };
  };

  hexRgb = hex: let
    n = i: (builtins.fromTOML "n = 0x${builtins.substring i 2 hex}").n;
  in "${toString (n 0)}, ${toString (n 2)}, ${toString (n 4)}";

  mkGtkCss = pal: let
    c = name: "#${pal.${name}}";
  in ''
    @define-color accent_color ${c "base0D"};
    @define-color accent_bg_color ${c "base0D"};
    @define-color accent_fg_color ${c "base00"};
    @define-color destructive_color ${c "base08"};
    @define-color destructive_bg_color ${c "base08"};
    @define-color destructive_fg_color ${c "base00"};
    @define-color success_color ${c "base0B"};
    @define-color success_bg_color ${c "base0B"};
    @define-color success_fg_color ${c "base00"};
    @define-color warning_color ${c "base0E"};
    @define-color warning_bg_color ${c "base0E"};
    @define-color warning_fg_color ${c "base00"};
    @define-color error_color ${c "base08"};
    @define-color error_bg_color ${c "base08"};
    @define-color error_fg_color ${c "base00"};
    @define-color window_bg_color ${c "base00"};
    @define-color window_fg_color ${c "base05"};
    @define-color view_bg_color ${c "base00"};
    @define-color view_fg_color ${c "base05"};
    @define-color headerbar_bg_color ${c "base01"};
    @define-color headerbar_fg_color ${c "base05"};
    @define-color headerbar_border_color rgba(${hexRgb pal.base01}, 0.7);
    @define-color headerbar_backdrop_color @window_bg_color;
    @define-color headerbar_shade_color rgba(0, 0, 0, 0.07);
    @define-color headerbar_darker_shade_color rgba(0, 0, 0, 0.07);
    @define-color sidebar_bg_color ${c "base01"};
    @define-color sidebar_fg_color ${c "base05"};
    @define-color sidebar_backdrop_color @window_bg_color;
    @define-color sidebar_shade_color rgba(0, 0, 0, 0.07);
    @define-color secondary_sidebar_bg_color @sidebar_bg_color;
    @define-color secondary_sidebar_fg_color @sidebar_fg_color;
    @define-color secondary_sidebar_backdrop_color @sidebar_backdrop_color;
    @define-color secondary_sidebar_shade_color @sidebar_shade_color;
    @define-color card_bg_color ${c "base01"};
    @define-color card_fg_color ${c "base05"};
    @define-color card_shade_color rgba(0, 0, 0, 0.07);
    @define-color dialog_bg_color ${c "base01"};
    @define-color dialog_fg_color ${c "base05"};
    @define-color popover_bg_color ${c "base01"};
    @define-color popover_fg_color ${c "base05"};
    @define-color popover_shade_color rgba(0, 0, 0, 0.07);
    @define-color shade_color rgba(0, 0, 0, 0.07);
    @define-color scrollbar_outline_color ${c "base02"};
  '';

  gtkCss = {
    dark = pkgs.writeText "stylix-gtk-dark.css" (mkGtkCss palettes.dark);
    light = pkgs.writeText "stylix-gtk-light.css" (mkGtkCss palettes.light);
  };

  # Official Gruvbox terminal colors (same as modules/tui/st-theme.nix).
  xresources = {
    light = pkgs.writeText "stylix-st-light.Xresources" ''
      st.foreground: #3c3836
      st.background: #fbf1c7
      st.cursorColor: #3c3836
      *foreground: #3c3836
      *background: #fbf1c7

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
    dark = pkgs.writeText "stylix-st-dark.Xresources" ''
      st.foreground: #ebdbb2
      st.background: #282828
      st.cursorColor: #ebdbb2
      *foreground: #ebdbb2
      *background: #282828

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
  };

  stylixTheme = pkgs.writeShellApplication {
    name = "stylix-theme";
    runtimeInputs = with pkgs; [
      coreutils
      dconf
      feh
      glib
      gnugrep
      procps
      xrdb
    ];
    text = ''
      set -euo pipefail

      mode="''${1:-auto}"
      if [[ "$mode" == "auto" ]]; then
        hour="$(date +%H)"
        if ((10#$hour >= 7 && 10#$hour < 18)); then
          mode="light"
        else
          mode="dark"
        fi
      fi

      state_home="''${XDG_STATE_HOME:-$HOME/.local/state}"
      state_file="$state_home/stylix-theme/current"

      if [[ "$mode" == "status" ]]; then
        if [[ -r "$state_file" ]]; then
          cat "$state_file"
        else
          echo "unknown"
        fi
        exit 0
      fi

      case "$mode" in
        light)
          gtk_css=${gtkCss.light}
          xres=${xresources.light}
          wallpaper=${wallpaperLight}
          color_scheme=prefer-light
          gtk_theme=adw-gtk3
          prefer_dark=0
          ;;
        dark)
          gtk_css=${gtkCss.dark}
          xres=${xresources.dark}
          wallpaper=${wallpaperDark}
          color_scheme=prefer-dark
          gtk_theme=adw-gtk3-dark
          prefer_dark=1
          ;;
        *)
          echo "Usage: stylix-theme [auto|light|dark|status]" >&2
          exit 2
          ;;
      esac

      export DISPLAY="''${DISPLAY:-:0}"
      export LC_ALL=C
      if [[ -z "''${XAUTHORITY:-}" && -f "$HOME/.Xauthority" ]]; then
        export XAUTHORITY="$HOME/.Xauthority"
      fi

      mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"
      install -m644 "$gtk_css" "$HOME/.config/gtk-3.0/gtk.css"
      install -m644 "$gtk_css" "$HOME/.config/gtk-4.0/gtk.css"
      cat >"$HOME/.config/gtk-3.0/settings.ini" <<EOF
      [Settings]
      gtk-theme-name=$gtk_theme
      gtk-application-prefer-dark-theme=$prefer_dark
      EOF
      cp "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"

      xrdb -merge "$xres" || true
      feh --no-fehbg --bg-fill "$wallpaper" || true

      gsettings set org.gnome.desktop.interface color-scheme "$color_scheme" || true
      gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme" || true

      mkdir -p "$(dirname "$state_file")"
      printf '%s\n' "$mode" >"$state_file"
      echo "stylix theme: $mode"
    '';
  };
in {
  environment.etc."stylix/gtk-dark.css".source = gtkCss.dark;
  environment.etc."stylix/gtk-light.css".source = gtkCss.light;

  environment.systemPackages = [
    stylixTheme
    pkgs.adw-gtk3
  ];

  # Keep the user manager (and 07:00/18:00 timer) alive across startx restarts.
  users.users.${userSettings.username}.linger = true;

  services.xserver.displayManager.startx.extraCommands = lib.mkAfter ''
    ${lib.getExe stylixTheme} auto || true
  '';

  systemd.user.services.stylix-theme-auto = {
    description = "Apply Stylix Gruvbox light or dark by local hour";
    wantedBy = ["default.target"];
    after = ["default.target"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${lib.getExe stylixTheme} auto";
      Environment = "DISPLAY=:0";
    };
  };

  systemd.user.timers.stylix-theme-auto = {
    description = "Switch Stylix Gruvbox by time of day";
    wantedBy = ["timers.target" "default.target"];
    timerConfig = {
      OnCalendar = [
        "*-*-* 07:00:00"
        "*-*-* 18:00:00"
      ];
      Persistent = true;
      Unit = "stylix-theme-auto.service";
    };
  };
}
