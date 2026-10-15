# Dunst styled after Omarchy's mako (default/mako/core.ini + themes/tokyo-night/mako.ini).
{ lib, ... }: {
  services.dunst = {
    enable = true;
    settings = {
      global = {
        origin = "top-right";
        width = 420;              # mako width=420
        offset = "(20, 20)";         # mako outer-margin=20
        padding = 10;             # mako padding=10,15
        horizontal_padding = 15;
        frame_width = 2;          # mako border-size=2
        corner_radius = 0;        # mako default (no radius)
        gap_size = 10;
        separator_height = 0;
        notification_limit = 5;
        font = "sans-serif 10.5"; # mako font=sans-serif 14px
        markup = "full";
        format = "<b>%s</b>\\n%b";
        icon_position = "left";
        max_icon_size = 32;       # mako max-icon-size=32
        stack_duplicates = true;  # mako group-by
        frame_color = "#33ccff";
        follow = "none";
      };
      urgency_low = { background = "#1a1b26"; foreground = "#c0caf5"; frame_color = "#33ccff"; timeout = 5; };
      urgency_normal = { background = "#1a1b26"; foreground = "#c0caf5"; frame_color = "#33ccff"; timeout = 5; };
      urgency_critical = { background = "#1a1b26"; foreground = "#c0caf5"; frame_color = "#f7768e"; timeout = 0; };
    };
  };
  # oxwm never reaches graphical-session.target: start with default.target on :0.
  systemd.user.services.dunst = {
    Unit.PartOf = lib.mkForce [ ];
    Unit.After = lib.mkForce [ ];
    Service.Environment = [ "DISPLAY=:0" ];
    Install.WantedBy = lib.mkForce [ "default.target" ];
  };
}
