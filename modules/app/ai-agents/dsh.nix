{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.ai.dsh;
in {
  config = lib.mkIf cfg.enable {
    home.packages = [cfg.package];
  };
}
