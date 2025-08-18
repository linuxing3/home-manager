{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
  ];

  home.file = {
    ".config/nvim" = {
      source = ../../uni-dotfiles/nvim;
      recursive = true;
    };
  };

}
