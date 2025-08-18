{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
  ];

  home.file = {
    ".config/kitty" = {
      source = ../../uni-dotfiles/kitty;
      recursive = true;
    };
  };

}
