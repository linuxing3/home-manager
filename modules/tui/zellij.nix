{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    zellij
  ];

  home.file = {
    ".config/zellij" = {
      source = ../../uni-dotfiles/zellij;
      recursive = true;
    };
  };

}
