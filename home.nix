{ config, pkgs, ... }:

{

  imports = [
    ./modules/gui/stylix.nix

    ./modules/wm/hyprland/hyprland.nix
    ./modules/gui/waybar.nix

    ./modules/app/ranger.nix
    ./modules/tui/zellij.nix
    ./modules/tui/tmux.nix
    ./modules/tui/kitty.nix
    ./modules/tui/alacritty.nix

    ./modules/editor/nvim.nix
  ];

  
  home.username = "efwmc";
  home.homeDirectory = "/home/efwmc";

  home.stateVersion = "25.05"; # Please read the comment before changing.
  home.packages = with pkgs; [
    gh
    git

    helix

    zellij
    tmux

    nnn

    cachix
  ];

  home.sessionVariables = {
    EDITOR = "helix";
  };

  programs.home-manager.enable = true;
}
