{
  config,
  userSettings,
  ...
}: {
  programs.waybar = {
    style =
      ''
        * {
            /* `otf-font-awesome` is required to be installed for icons */
            font-family: FontAwesome, ''
      + userSettings.font
      + ''        ;

                  font-size: 20px;
              }

              window#waybar {
                  background-color: rgba(''
      + config.lib.stylix.colors.base00-rgb-r
      + ","
      + config.lib.stylix.colors.base00-rgb-g
      + ","
      + config.lib.stylix.colors.base00-rgb-b
      + ","
      + ''        0.55);
                  border-radius: 8px;
                  color: #''
      + config.lib.stylix.colors.base07
      + ''        ;
                  transition-property: background-color;
                  transition-duration: .2s;
              }

              tooltip {
                color: #''
      + config.lib.stylix.colors.base07
      + ''        ;
                background-color: rgba(''
      + config.lib.stylix.colors.base00-rgb-r
      + ","
      + config.lib.stylix.colors.base00-rgb-g
      + ","
      + config.lib.stylix.colors.base00-rgb-b
      + ","
      + ''        0.9);
                border-style: solid;
                border-width: 3px;
                border-radius: 8px;
                border-color: #''
      + config.lib.stylix.colors.base08
      + ''        ;
              }

              tooltip * {
                color: #''
      + config.lib.stylix.colors.base07
      + ''        ;
                background-color: rgba(''
      + config.lib.stylix.colors.base00-rgb-r
      + ","
      + config.lib.stylix.colors.base00-rgb-g
      + ","
      + config.lib.stylix.colors.base00-rgb-b
      + ","
      + ''        0.0);
              }

              window > box {
                  border-radius: 8px;
                  opacity: 0.94;
              }

              window#waybar.hidden {
                  opacity: 0.2;
              }

              button {
                  border: none;
              }

              #custom-hyprprofile {
                  color: #''
      + config.lib.stylix.colors.base0D
      + ''        ;
              }

              /* https://github.com/Alexays/Waybar/wiki/FAQ#the-workspace-buttons-have-a-strange-hover-effect */
              button:hover {
                  background: inherit;
              }

              #workspaces button {
                  padding: 0px 6px;
                  background-color: transparent;
                  color: #''
      + config.lib.stylix.colors.base04
      + ''        ;
              }

              #workspaces button:hover {
                  color: #''
      + config.lib.stylix.colors.base07
      + ''        ;
              }

              #workspaces button.active {
                  color: #''
      + config.lib.stylix.colors.base08
      + ''        ;
              }

              #workspaces button.focused {
                  color: #''
      + config.lib.stylix.colors.base0A
      + ''        ;
              }

              #workspaces button.visible {
                  color: #''
      + config.lib.stylix.colors.base05
      + ''        ;
              }

              #workspaces button.urgent {
                  color: #''
      + config.lib.stylix.colors.base09
      + ''        ;
              }

              #battery,
              #cpu,
              #memory,
              #disk,
              #temperature,
              #backlight,
              #network,
              #pulseaudio,
              #wireplumber,
              #custom-media,
              #tray,
              #mode,
              #idle_inhibitor,
              #scratchpad,
              #custom-hyprprofileicon,
              #custom-quit,
              #custom-lock,
              #custom-reboot,
              #custom-power,
              #mpd {
                  padding: 0 3px;
                  color: #''
      + config.lib.stylix.colors.base07
      + ''        ;
                  border: none;
                  border-radius: 8px;
              }

              #custom-hyprprofileicon,
              #custom-quit,
              #custom-lock,
              #custom-reboot,
              #custom-power,
              #idle_inhibitor {
                  background-color: transparent;
                  color: #''
      + config.lib.stylix.colors.base04
      + ''        ;
              }

              #custom-hyprprofileicon:hover,
              #custom-quit:hover,
              #custom-lock:hover,
              #custom-reboot:hover,
              #custom-power:hover,
              #idle_inhibitor:hover {
                  color: #''
      + config.lib.stylix.colors.base07
      + ''        ;
              }

              #clock, #tray, #idle_inhibitor {
                  padding: 0 5px;
              }

              #window,
              #workspaces {
                  margin: 0 6px;
              }

              /* If workspaces is the leftmost module, omit left margin */
              .modules-left > widget:first-child > #workspaces {
                  margin-left: 0;
              }

              /* If workspaces is the rightmost module, omit right margin */
              .modules-right > widget:last-child > #workspaces {
                  margin-right: 0;
              }

              #clock {
                  color: #''
      + config.lib.stylix.colors.base0D
      + ''        ;
              }

              #battery {
                  color: #''
      + config.lib.stylix.colors.base0B
      + ''        ;
              }

              #battery.charging, #battery.plugged {
                  color: #''
      + config.lib.stylix.colors.base0C
      + ''        ;
              }

              @keyframes blink {
                  to {
                      background-color: #''
      + config.lib.stylix.colors.base07
      + ''        ;
                      color: #''
      + config.lib.stylix.colors.base00
      + ''        ;
                  }
              }

              #battery.critical:not(.charging) {
                  background-color: #''
      + config.lib.stylix.colors.base08
      + ''        ;
                  color: #''
      + config.lib.stylix.colors.base07
      + ''        ;
                  animation-name: blink;
                  animation-duration: 0.5s;
                  animation-timing-function: linear;
                  animation-iteration-count: infinite;
                  animation-direction: alternate;
              }

              label:focus {
                  background-color: #''
      + config.lib.stylix.colors.base00
      + ''        ;
              }

              #cpu {
                  color: #''
      + config.lib.stylix.colors.base0D
      + ''        ;
              }

              #memory {
                  color: #''
      + config.lib.stylix.colors.base0E
      + ''        ;
              }

              #disk {
                  color: #''
      + config.lib.stylix.colors.base0F
      + ''        ;
              }

              #backlight {
                  color: #''
      + config.lib.stylix.colors.base0A
      + ''        ;
              }

              label.numlock {
                  color: #''
      + config.lib.stylix.colors.base04
      + ''        ;
              }

              label.numlock.locked {
                  color: #''
      + config.lib.stylix.colors.base0F
      + ''        ;
              }

              #pulseaudio {
                  color: #''
      + config.lib.stylix.colors.base0C
      + ''        ;
              }

              #pulseaudio.muted {
                  color: #''
      + config.lib.stylix.colors.base04
      + ''        ;
              }

              #tray > .passive {
                  -gtk-icon-effect: dim;
              }

              #tray > .needs-attention {
                  -gtk-icon-effect: highlight;
              }

              #idle_inhibitor {
                  color: #''
      + config.lib.stylix.colors.base04
      + ''        ;
              }

              #idle_inhibitor.activated {
                  color: #''
      + config.lib.stylix.colors.base0F
      + ''        ;
              }
      '';
  };
}
