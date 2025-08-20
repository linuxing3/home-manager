{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    alacritty
  ];

  home.file = {
    ".config/alacritty" = {
      source = ../../uni-dotfiles/alacritty;
      recursive = true;
    };
  };

}
