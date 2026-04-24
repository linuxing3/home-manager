{ config, lib, pkgs, ... }:
let
  cfg = config.my.features.home;
in
{
  options.my.features.home.zellij = lib.mkEnableOption "Enable zellij module";

  config = lib.mkIf cfg.zellij {
    home.packages = with pkgs; [
      zellij
    ];

    home.file = {
      ".config/zellij" = {
        source = ../../configs/zellij;
        recursive = true;
      };
    };
  };
}
