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
      # HM copies this file over ~/.omp/agent/config.yml on every switch.
      # Without a pinned setupVersion / setupWizard=false, that wipe resets
      # onboarding to 0 and re-runs provider/model/theme scenes on next launch.
      settings = {
        setupVersion = 2; # packages/tui/src/setup/setup-version.ts CURRENT_SETUP_VERSION
        startup = {
          quiet = true;
          setupWizard = false;
        };
        symbolPreset = "unicode";
        composer.shape = "band";
        theme.dark = "titanium";
        modelRoles.default = "cursor/default";
        defaultThinkingLevel = "auto";
        providers.webSearchOrder = [];
      };
    };
  };
}
