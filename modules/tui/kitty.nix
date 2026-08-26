{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.features.home;
in {
  options.my.features.home.kitty = lib.mkEnableOption "Enable kitty module";

  config = lib.mkIf cfg.kitty {
    home.packages = with pkgs; [
      kitty.terminfo
      (writeShellScriptBin "kitty" ''
        exec ${kitty}/bin/kitty "$@"
      '')
    ];

    home.file = {
      ".config/kitty" = {
        source = ../../configs/kitty;
        recursive = true;
      };
    };
  };
}
