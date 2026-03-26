{ config, pkgs, inputs, ... }:

{
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
  };
  home.file.".config/nvim".source = ../../../configs/nvim;
  home.file.".config/nvim".recursive = true;
  home.file.".config/nvim/lua".lua = ../../../configs/nvim/lua;
  home.file.".config/nvim/lua".recursive = true;
}
