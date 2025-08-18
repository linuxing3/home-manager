{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
  ];

  home.file = {
    ".config/zellij" = {
      source = ../../uni-dotfiles/zellij;
      recursive = true;
    };
  };

}
