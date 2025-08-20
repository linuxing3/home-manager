{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    tmux
  ];

  home.file = {
    ".config/tmux" = {
      source = ../../uni-dotfiles/tmux;
      recursive = true;
    };
  };

}
