{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
  ];

  home.file = {
    ".config/alacritty" = {
      source = ../../uni-dotfiles/alacritty;
      recursive = true;
    };
  };

}
