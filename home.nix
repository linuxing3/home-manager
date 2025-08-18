{ config, pkgs, ... }:

{

  imports = [
    ./modules/gui/stylix.nix
    ./modules/wm/hyprland/hyprland.nix
    ./modules/gui/waybar.nix

    ./modules/tui/zellij.nix
    ./modules/tui/tmux.nix
    ./modules/tui/kitty.nix
    ./modules/tui/alacritty.nix
    ./modules/shell/sh.nix

    ./modules/editor/nvim.nix
  ];

  
  home.username = "efwmc";
  home.homeDirectory = "/home/efwmc";

  home.stateVersion = "25.05"; # Please read the comment before changing.
  home.packages = with pkgs; [
    gh
  ];

  home.sessionVariables = {
    EDITOR = "helix";
  };

  programs.home-manager.enable = true;
}
