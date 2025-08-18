{
  pkgs,
  lib,
  ...
}: {
  home.packages = with pkgs; [
    kitty
  ];
  programs.kitty.enable = true;
  programs.kitty.settings = {
    background_opacity = lib.mkForce "0.85";
    modify_font = "cell_width 90%";
    allow_remote_control = true;
    listen_on = "unix:/tmp/kitty";
    enabled_layouts = "splits:split_axis=horizontal";
  };
  programs.kitty.keybindings = {
    "ctrl+c" = "copy_or_interrupt";

    "ctrl+f>2" = "set_font_size 20";

    "ctrl+f5" = "launch --location=hsplit";
    "ctrl+f6" = "launch --location=vsplit";
    "ctrl+f7" = "layout_action rotate";

    "shift+up" = "move_window up";
    "shift+left" = "move_window left";
    "shift+right" = "move_window right";
    "shift+down" = "move_window down";

    "ctrl+shift+up" = "layout_action move_to_screen_edge top";
    "ctrl+shift+left" = "layout_action move_to_screen_edge left";
    "ctrl+shift+right" = "layout_action move_to_screen_edge right";
    "ctrl+shift+down" = "layout_action move_to_screen_edge bottom";

    "ctrl+left" = "neighboring_window left";
    "ctrl+right" = "neighboring_window right";
    "ctrl+up" = "neighboring_window up";
    "ctrl+down" = "neighboring_window down";

    "ctrl+alt+left" = "resize_window narrower";
    "ctrl+alt+right" = "resize_window wider";
    "ctrl+alt+up" = "resize_window taller";
    "ctrl+alt+down" = "resize_window shorter 3";

    "ctrl+home " = "resize_window reset";
  };
}
