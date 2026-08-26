{
  pkgs,
  userSettings,
  lib,
  ...
}: {
  imports = [
    ../../security/security.nix
    ../../modules/shell/sh.nix
    ../../modules/shell/cli-collection.nix
    ../../modules/app/git/git.nix
    ../../modules/app/ranger/ranger.nix
    ../../modules/app/ai-agents
    ../../modules/app/personal-configs
    ../../modules/app/cloudflared-office.nix
    ../../modules/app/credential-backup
    ../../modules/app/secretspec-bitwarden
    ../../modules/tui/st-theme.nix
    ../../modules/app/nvim/nvim.nix
    ../../modules/app/hx-anywhere
    ../../modules/app/rclone
    ../../modules/app/crabbox
    ../../modules/app/virtualization
    ../../modules/wm/oxwm/oxwm.nix
    ../../modules/wm/xmonad
    ../../modules/wm/dwm
    ../../modules/hardware/ft-hda-audio.nix
    ./packages.nix
  ];

  home.username = userSettings.username;
  home.homeDirectory = "/home/" + userSettings.username;
  home.enableNixpkgsReleaseCheck = false;

  my.features.home.nvim = true;
  my.ai.herdr.enable = true;
  my.ai.pi.enable = true;
  my.ai.collie.enable = true;
  my.ai.orca.enable = true;
  my.ai.cursorAgent.enable = true;
  my.ai.cliProxyApi.enable = true;

  home.stateVersion = "25.11";

  home.sessionVariables = {
    EDITOR = userSettings.editor;
    VISUAL = userSettings.editor;
    SPAWNEDITOR = userSettings.spawnEditor;
    AI_BROWSER = lib.getExe pkgs.agent-browser;
    AGENT_BROWSER = lib.getExe pkgs.agent-browser;
    BROWSER = userSettings.browser;
    XDG_SESSION_TYPE = "x11";
  };

  news.display = "silent";

  programs.home-manager.enable = true;
}
