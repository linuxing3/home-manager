{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
  ];

  home.file = {
    ".config/tmux" = {
      source = ../../uni-dotfiles/tmux;
      recursive = true;
    };
  };

}
