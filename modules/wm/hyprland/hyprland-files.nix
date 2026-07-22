{
  config,
  lib,
  userSettings,
  ...
}:
let
  cfg = config.my.features.home;
in
{
  config = lib.mkIf cfg.hyprland {
  # --- Generated desktop assets and dock styling ---------------------------
  home.file.".local/share/pixmaps/hyprland-logo-stylix.svg".source = config.lib.stylix.colors {
    template = builtins.readFile ../../pkgs/hyprland-logo-stylix.svg.mustache;
    extension = "svg";
  };
  home.file.".config/nwg-dock-hyprland/style.css".text =
    ''
      window {
        background: rgba(''
    + config.lib.stylix.colors.base00-rgb-r
    + '',''
    + config.lib.stylix.colors.base00-rgb-g
    + '',''
    + config.lib.stylix.colors.base00-rgb-b
    + ''
      ,0.0);
            border-radius: 20px;
            padding: 4px;
            margin-left: 4px;
            margin-right: 4px;
            border-style: none;
          }

          #box {
            /* Define attributes of the box surrounding icons here */
            padding: 10px;
            background: rgba(''
    + config.lib.stylix.colors.base00-rgb-r
    + '',''
    + config.lib.stylix.colors.base00-rgb-g
    + '',''
    + config.lib.stylix.colors.base00-rgb-b
    + ''
      ,0.55);
            border-radius: 20px;
            padding: 4px;
            margin-left: 4px;
            margin-right: 4px;
            border-style: none;
          }
          button {
            border-radius: 10px;
            padding: 4px;
            margin-left: 4px;
            margin-right: 4px;
            background: rgba(''
    + config.lib.stylix.colors.base03-rgb-r
    + '',''
    + config.lib.stylix.colors.base03-rgb-g
    + '',''
    + config.lib.stylix.colors.base03-rgb-b
    + ''
      ,0.55);
            color: #''
    + config.lib.stylix.colors.base07
    + ''
      ;
            font-size: 12px
          }

          button:hover {
            background: rgba(''
    + config.lib.stylix.colors.base04-rgb-r
    + '',''
    + config.lib.stylix.colors.base04-rgb-g
    + '',''
    + config.lib.stylix.colors.base04-rgb-b
    + ''
      ,0.55);
          }

    '';
  home.file.".config/nwg-dock-pinned".text = ''
    nwggrid
    Alacritty
    neovide
    qutebrowser
    brave-browser
    writer
    impress
    calc
    draw
    krita
    xournalpp
    obs
    kdenlive
    flstudio
    blender
    openscad
    Cura
    virt-manager
  '';
  # --- Idle, lock, and auth screens ----------------------------------------
  home.file.".config/hypr/hypridle.conf".text = ''
    general {
      lock_cmd = pgrep hyprlock || hyprlock
      before_sleep_cmd = loginctl lock-session
      ignore_dbus_inhibit = false
    }

    # FIXME memory leak fries computer inbetween dpms off and suspend
    #listener {
    #  timeout = 150 # in seconds
    #  on-timeout = hyprctl dispatch dpms off
    #  on-resume = hyprctl dispatch dpms on
    #}
    listener {
      timeout = 165 # in seconds
      on-timeout = loginctl lock-session
    }
    listener {
      timeout = 180 # in seconds
      #timeout = 5400 # in seconds
      on-timeout = systemctl suspend
      on-resume = hyprctl dispatch dpms on
    }
  '';
  home.file.".config/hypr/hyprlock.conf".text =
    ''
      background {
        monitor =
        path = screenshot

        # all these options are taken from hyprland, see https://wiki.hyprland.org/Configuring/Variables/#blur for explanations
        blur_passes = 4
        blur_size = 5
        noise = 0.0117
        contrast = 0.8916
        brightness = 0.8172
        vibrancy = 0.1696
        vibrancy_darkness = 0.0
      }

      # doesn't work yet
      image {
        monitor =
        path = /home/${userSettings.username}/.config/dotfiles/modules/wm/hyprland/nix-dark.png
        size = 150 # lesser side if not 1:1 ratio
        rounding = -1 # negative values mean circle
        border_size = 0
        rotate = 0 # degrees, counter-clockwise

        position = 0, 200
        halign = center
        valign = center
      }

      input-field {
        monitor =
        size = 200, 50
        outline_thickness = 3
        dots_size = 0.33 # Scale of input-field height, 0.2 - 0.8
        dots_spacing = 0.15 # Scale of dots' absolute size, 0.0 - 1.0
        dots_center = false
        dots_rounding = -1 # -1 default circle, -2 follow input-field rounding
        outer_color = rgb(''
    + config.lib.stylix.colors.base07-rgb-r
    + '',''
    + config.lib.stylix.colors.base07-rgb-g
    + '', ''
    + config.lib.stylix.colors.base07-rgb-b
    + ''
      )
            inner_color = rgb(''
    + config.lib.stylix.colors.base00-rgb-r
    + '',''
    + config.lib.stylix.colors.base00-rgb-g
    + '', ''
    + config.lib.stylix.colors.base00-rgb-b
    + ''
      )
            font_color = rgb(''
    + config.lib.stylix.colors.base07-rgb-r
    + '',''
    + config.lib.stylix.colors.base07-rgb-g
    + '', ''
    + config.lib.stylix.colors.base07-rgb-b
    + ''
      )
            fade_on_empty = true
            fade_timeout = 1000 # Milliseconds before fade_on_empty is triggered.
            placeholder_text = <i>Input Password...</i> # Text rendered in the input box when it's empty.
            hide_input = false
            rounding = -1 # -1 means complete rounding (circle/oval)
            check_color = rgb(''
    + config.lib.stylix.colors.base0A-rgb-r
    + '',''
    + config.lib.stylix.colors.base0A-rgb-g
    + '', ''
    + config.lib.stylix.colors.base0A-rgb-b
    + ''
      )
            fail_color = rgb(''
    + config.lib.stylix.colors.base08-rgb-r
    + '',''
    + config.lib.stylix.colors.base08-rgb-g
    + '', ''
    + config.lib.stylix.colors.base08-rgb-b
    + ''
      )
            fail_text = <i>$FAIL <b>($ATTEMPTS)</b></i> # can be set to empty
            fail_transition = 300 # transition time in ms between normal outer_color and fail_color
            capslock_color = -1
            numlock_color = -1
            bothlock_color = -1 # when both locks are active. -1 means don't change outer color (same for above)
            invert_numlock = false # change color if numlock is off
            swap_font_color = false # see below

            position = 0, -20
            halign = center
            valign = center
          }

          label {
            monitor =
            text = Hello, ${userSettings.username}
            color = rgb(''
    + config.lib.stylix.colors.base07-rgb-r
    + '',''
    + config.lib.stylix.colors.base07-rgb-g
    + '', ''
    + config.lib.stylix.colors.base07-rgb-b
    + ''
      )
            font_size = 25
            font_family = ''
    + userSettings.font
    + ''

        rotate = 0 # degrees, counter-clockwise

        position = 0, 160
        halign = center
        valign = center
      }

      label {
        monitor =
        text = $TIME
        color = rgb(''
    + config.lib.stylix.colors.base07-rgb-r
    + '',''
    + config.lib.stylix.colors.base07-rgb-g
    + '', ''
    + config.lib.stylix.colors.base07-rgb-b
    + ''
      )
            font_size = 20
            font_family = Intel One Mono
            rotate = 0 # degrees, counter-clockwise

            position = 0, 80
            halign = center
            valign = center
          }
    '';

  # --- On-screen feedback and launcher styling -----------------------------
  services.swayosd.enable = true;
  services.swayosd.topMargin = 0.5;

  home.file.".config/gtklock/style.css".text =
    ''
      window {
        background-image: url("''
    + config.stylix.image
    + ''
      ");
            background-size: auto 100%;
          }
    '';
  home.file.".config/nwg-launchers/nwggrid/style.css".text =
    ''
      button, label, image {
          background: none;
          border-style: none;
          box-shadow: none;
          color: #''
    + config.lib.stylix.colors.base07
    + ''
      ;

              font-size: 20px;
          }

          button {
              padding: 5px;
              margin: 5px;
              text-shadow: none;
          }

          button:hover {
              background-color: rgba(''
    + config.lib.stylix.colors.base07-rgb-r
    + ","
    + config.lib.stylix.colors.base07-rgb-g
    + ","
    + config.lib.stylix.colors.base07-rgb-b
    + ","
    + ''
      0.15);
          }

          button:focus {
              box-shadow: 0 0 10px;
          }

          button:checked {
              background-color: rgba(''
    + config.lib.stylix.colors.base07-rgb-r
    + ","
    + config.lib.stylix.colors.base07-rgb-g
    + ","
    + config.lib.stylix.colors.base07-rgb-b
    + ","
    + ''
      0.15);
          }

          #searchbox {
              background: none;
              border-color: #''
    + config.lib.stylix.colors.base07
    + ''
      ;

              color: #''
    + config.lib.stylix.colors.base07
    + ''
      ;

              margin-top: 20px;
              margin-bottom: 20px;

              font-size: 20px;
          }

          #separator {
              background-color: rgba(''
    + config.lib.stylix.colors.base00-rgb-r
    + ","
    + config.lib.stylix.colors.base00-rgb-g
    + ","
    + config.lib.stylix.colors.base00-rgb-b
    + ","
    + ''
      0.55);

              color: #''
    + config.lib.stylix.colors.base07
    + ''
      ;
              margin-left: 500px;
              margin-right: 500px;
              margin-top: 10px;
              margin-bottom: 10px
          }

          #description {
              margin-bottom: 20px
          }
    '';
  home.file.".config/nwg-launchers/nwggrid/terminal".text = "alacritty -e";
  home.file.".config/nwg-drawer/drawer.css".text =
    ''
      window {
          background-color: rgba(''
    + config.lib.stylix.colors.base00-rgb-r
    + ","
    + config.lib.stylix.colors.base00-rgb-g
    + ","
    + config.lib.stylix.colors.base00-rgb-b
    + ","
    + ''
      0.55);
              color: #''
    + config.lib.stylix.colors.base07
    + ''
      }

      /* search entry */
      entry {
          background-color: rgba(''
    + config.lib.stylix.colors.base01-rgb-r
    + ","
    + config.lib.stylix.colors.base01-rgb-g
    + ","
    + config.lib.stylix.colors.base01-rgb-b
    + ","
    + ''
      0.45);
          }

          button, image {
              background: none;
              border: none
          }

          button:hover {
              background-color: rgba(''
    + config.lib.stylix.colors.base02-rgb-r
    + ","
    + config.lib.stylix.colors.base02-rgb-g
    + ","
    + config.lib.stylix.colors.base02-rgb-b
    + ","
    + ''
      0.45);
          }

          /* in case you wanted to give category buttons a different look */
          #category-button {
              margin: 0 10px 0 10px
          }

          #pinned-box {
              padding-bottom: 5px;
              border-bottom: 1px dotted;
              border-color: #''
    + config.lib.stylix.colors.base07
    + ''
      ;
          }

          #files-box {
              padding: 5px;
              border: 1px dotted gray;
              border-radius: 15px
              border-color: #''
    + config.lib.stylix.colors.base07
    + ''
      ;
          }
    '';

  # services.udiskie.enable = true;
  # services.udiskie.tray = "always";
  };
}
