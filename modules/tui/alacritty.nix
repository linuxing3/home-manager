{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    alacritty
  ];

  home.file = {
    ".config/alacritty" = {
      source = ../../configs/alacritty;
      recursive = true;
    };
  };

}
