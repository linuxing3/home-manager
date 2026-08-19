{
  config,
  lib,
  pkgs,
  ...
}: let
  ai = import ./lib.nix {inherit config lib pkgs;};
  ccSwitchDefaults = pkgs.writeText "cc-switch-defaults.json" (builtins.toJSON {
    showInTray = true;
    minimizeToTrayOnClose = true;
    commonConfigConfirmed = true;
    usageConfirmed = true;
    visibleApps = {
      codex = true;
      opencode = true;
      openclaw = true;
    };
    visibleAppsSettings = {
      mode = "manual";
      autoPromptDecided = true;
    };
    language = "zh";
    skillSyncMethod = "auto";
  });
in {
  home.activation.mergeCcSwitchSettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${ai.activationPreamble}
    ${ai.mergeJsonFile "${ai.homeDir}/.cc-switch/settings.json" ccSwitchDefaults}
  '';
}
