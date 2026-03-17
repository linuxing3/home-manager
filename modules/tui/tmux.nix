{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    tmux
  ];

  home.file = {
    ".config/tmux" = {
      source = ../../configs/tmux;
      recursive = true;
    };
  };

}
