{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
  ];

  home.file = {
    ".config/hypr" = {
      source = ../uni-dotfiles/hypr;
      recursive = true;
    };
  };

}
