{ config, lib, pkgs, inputs, ... }:
let
  cfg = config.my.features.home;
in
{
  options.my.features.home.nvim = lib.mkEnableOption "Enable nvim module";

  config = lib.mkIf cfg.nvim {
    programs.neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
    };
    home.file.".config/nvim" = {
      source = ../../../configs/nvim;
      recursive = true;
    };
  };
}
