{...}: {
  # --- Waybar module graph --------------------------------------------------
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 35;
        margin = "7 7 3 7";
        spacing = 2;

        modules-left = ["group/power" "group/battery" "group/backlight" "group/cpu" "group/memory" "group/pulseaudio" "keyboard-state"];
        modules-center = ["custom/hyprprofile" "hyprland/workspaces"];
        modules-right = ["group/time" "idle_inhibitor" "tray"];

        "custom/os" = {
          "format" = " {} ";
          "exec" = ''echo "" '';
          "interval" = "once";
          "on-click" = "nwggrid-wrapper";
          "tooltip" = false;
        };
        "group/power" = {
          "orientation" = "horizontal";
          "drawer" = {
            "transition-duration" = 500;
            "children-class" = "not-power";
            "transition-left-to-right" = true;
          };
          "modules" = [
            "custom/os"
            "custom/hyprprofileicon"
            "custom/lock"
            "custom/quit"
            "custom/power"
            "custom/reboot"
          ];
        };
        "custom/quit" = {
          "format" = "󰍃";
          "tooltip" = false;
          "on-click" = "hyprctl dispatch exit";
        };
        "custom/lock" = {
          "format" = "󰍁";
          "tooltip" = false;
          "on-click" = "hyprlock";
        };
        "custom/reboot" = {
          "format" = "󰜉";
          "tooltip" = false;
          "on-click" = "reboot";
        };
        "custom/power" = {
          "format" = "󰐥";
          "tooltip" = false;
          "on-click" = "shutdown now";
        };
        "custom/hyprprofileicon" = {
          "format" = "󱙋";
          "on-click" = "hyprprofile-dmenu";
          "tooltip" = false;
        };
        "custom/hyprprofile" = {
          "format" = " {}";
          "exec" = ''cat ~/.hyprprofile'';
          "interval" = 3;
          "on-click" = "hyprprofile-dmenu";
        };
        "keyboard-state" = {
          "numlock" = true;
          "format" = "{icon}";
          "format-icons" = {
            "locked" = "󰎠 ";
            "unlocked" = "󱧓 ";
          };
        };
        "hyprland/workspaces" = {
          "format" = "{icon}";
          "format-icons" = {
            "1" = "󱚌";
            "2" = "󰖟";
            "3" = "";
            "4" = "󰎄";
            "5" = "󰋩";
            "6" = "";
            "7" = "󰄖";
            "8" = "󰑴";
            "9" = "󱎓";
            "scratch_term" = "_";
            "scratch_ranger" = "_󰴉";
            "scratch_music" = "_";
            "scratch_btm" = "_";
            "scratch_pavucontrol" = "_󰍰";
          };
          "on-click" = "activate";
          "on-scroll-up" = "hyprnome";
          "on-scroll-down" = "hyprnome --previous";
          "all-outputs" = false;
          "active-only" = false;
          "ignore-workspaces" = ["scratch" "-"];
          "show-special" = false;
        };

        "idle_inhibitor" = {
          format = "{icon}";
          format-icons = {
            activated = "󰅶";
            deactivated = "󰾪";
          };
        };
        tray = {
          #"icon-size" = 21;
          "spacing" = 10;
        };
        "clock#time" = {
          "interval" = 1;
          "format" = "{:%I:%M:%S %p}";
          "timezone" = "America/Sao_Paulo";
          "tooltip-format" = ''
            <big>{:%Y %B}</big>
            <tt><small>{calendar}</small></tt>'';
        };
        "clock#date" = {
          "interval" = 1;
          "format" = "{:%a %Y-%m-%d}";
          "timezone" = "America/Sao_Paulo";
          "tooltip-format" = ''
            <big>{:%Y %B}</big>
            <tt><small>{calendar}</small></tt>'';
        };
        "group/time" = {
          "orientation" = "horizontal";
          "drawer" = {
            "transition-duration" = 500;
            "transition-left-to-right" = false;
          };
          "modules" = ["clock#time" "clock#date"];
        };

        cpu = {"format" = "󰍛";};
        "cpu#text" = {"format" = "{usage}%";};
        "group/cpu" = {
          "orientation" = "horizontal";
          "drawer" = {
            "transition-duration" = 500;
            "transition-left-to-right" = true;
          };
          "modules" = ["cpu" "cpu#text"];
        };

        memory = {"format" = "";};
        "memory#text" = {"format" = "{}%";};
        "group/memory" = {
          "orientation" = "horizontal";
          "drawer" = {
            "transition-duration" = 500;
            "transition-left-to-right" = true;
          };
          "modules" = ["memory" "memory#text"];
        };

        backlight = {
          "format" = "{icon}";
          "format-icons" = ["" "" "" "" "" "" "" "" ""];
        };
        "backlight#text" = {"format" = "{percent}%";};
        "group/backlight" = {
          "orientation" = "horizontal";
          "drawer" = {
            "transition-duration" = 500;
            "transition-left-to-right" = true;
          };
          "modules" = ["backlight" "backlight#text"];
        };

        battery = {
          "states" = {
            "good" = 75;
            "warning" = 30;
            "critical" = 15;
          };
          "fullat" = 80;
          "format" = "{icon}";
          "format-charging" = "󰂄";
          "format-plugged" = "󰂄";
          "format-full" = "󰁹";
          "format-icons" = ["󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹"];
          "interval" = 10;
        };
        "battery#text" = {
          "states" = {
            "good" = 75;
            "warning" = 30;
            "critical" = 15;
          };
          "fullat" = 80;
          "format" = "{capacity}%";
        };
        "group/battery" = {
          "orientation" = "horizontal";
          "drawer" = {
            "transition-duration" = 500;
            "transition-left-to-right" = true;
          };
          "modules" = ["battery" "battery#text"];
        };
        pulseaudio = {
          "scroll-step" = 1;
          "format" = "{icon}";
          "format-bluetooth" = "{icon}";
          "format-bluetooth-muted" = "󰸈";
          "format-muted" = "󰸈";
          "format-source" = "";
          "format-source-muted" = "";
          "format-icons" = {
            "headphone" = "";
            "hands-free" = "";
            "headset" = "";
            "phone" = "";
            "portable" = "";
            "car" = "";
            "default" = ["" "" ""];
          };
          "on-click" = "hyprctl dispatch togglespecialworkspace scratch_pavucontrol; if hyprctl clients | grep pavucontrol; then echo 'scratch_ranger respawn not needed'; else pavucontrol; fi";
        };
        "pulseaudio#text" = {
          "scroll-step" = 1;
          "format" = "{volume}%";
          "format-bluetooth" = "{volume}%";
          "format-bluetooth-muted" = "";
          "format-muted" = "";
          "format-source" = "{volume}%";
          "format-source-muted" = "";
          "on-click" = "hyprctl dispatch togglespecialworkspace scratch_pavucontrol; if hyprctl clients | grep pavucontrol; then echo 'scratch_ranger respawn not needed'; else pavucontrol; fi";
        };
        "group/pulseaudio" = {
          "orientation" = "horizontal";
          "drawer" = {
            "transition-duration" = 500;
            "transition-left-to-right" = true;
          };
          "modules" = ["pulseaudio" "pulseaudio#text"];
        };
      };
    };
  };
}
