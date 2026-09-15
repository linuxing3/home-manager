{
  config,
  lib,
  inputs,
  ...
}: let
  cfg = config.my.ai.omp;
in {
  imports = [inputs.omp.homeManagerModules.default];

  config = lib.mkIf cfg.enable {
    programs.omp = {
      enable = true;
      inherit (cfg) package;
      settings.startup.quiet = true;
    };
  };
}
