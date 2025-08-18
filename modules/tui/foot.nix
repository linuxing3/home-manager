{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
  ];

  home.file = {
    ".config/foot" = {
      source = ../uni-dotfiles/foot;
      recursive = true;
    };
  };

}
