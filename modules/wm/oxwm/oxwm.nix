{pkgs, ...}: let
  screenshot-to-clipboard = pkgs.writeShellApplication {
    name = "screenshot-to-clipboard";
    runtimeInputs = with pkgs; [
      maim
      xclip
    ];
    text = ''
      maim --select | xclip -selection clipboard -target image/png -in
    '';
  };
in {
  imports = [
    ../input/chinese-sogou.nix
  ];
  home.packages = with pkgs; [
    oxwm
    dmenu
    feh
    screenshot-to-clipboard
  ];

  home.file.".config/oxwm/config.lua".source = ./config.lua;
}
