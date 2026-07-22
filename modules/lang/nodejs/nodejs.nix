{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.features.home;
in
{
  options.my.features.home.nodejs = lib.mkEnableOption "Enable Node.js module";

  config = lib.mkIf cfg.nodejs {
    home.packages = with pkgs; [
      nodejs
      nodePackages.mermaid-cli
    ];
  };
}
