{
  pkgs,
  inputs,
  userSettings,
  systemSettings,
  lib,
  ...
}: let
  baseImports = [
    # ------------- security -------------------
    ../../security/security.nix

    # ------------- style -------------------
    # ../../modules/gui/stylix.nix

    # ------------- cli -------------------
    ../../modules/shell/sh.nix
    ../../modules/shell/cli-collection.nix
    ../../modules/app/git/git.nix
    ../../modules/app/ranger/ranger.nix

    # ------------- editor -------------------
    # ../../modules/app/nixvim

    # ------------- app -------------------
    # ../../modules/app/mail/default.nix
    # ../../modules/app/hermes/default.nix
    # ../../modules/app/hermes-python-tools/default.nix
    # ../../modules/app/playwright/default.nix
    # ../../modules/app/rclone/default.nix
    # ../../modules/app/browser/librewolf.nix

    # ------------- wm/gui -------------------
    # ../../modules/gui/fuzzel.nix
    # ../../modules/wm/oxwm/oxwm.nix
  ];
  fileManagerPackages = with pkgs; [
    yazi
    nnn
  ];
  terminalPackages = with pkgs; [
    dwm
    st
  ];
  editorPackages = with pkgs; [
    helix
  ];
  collaborationPackages = with pkgs; [
    git
    gh
    lazygit
    zellij
  ];
  workflowPackages = with pkgs; [
    just
    comma
    cachix
  ];
  desktopMediaPackages = with pkgs; [
    librewolf
    nautilus
    pcmanfm
    imv
    sxiv
    nsxiv
    vlc
    mpv
    viu
  ];
in {
  imports = baseImports;
  home.username = userSettings.username;
  home.homeDirectory = "/home/" + userSettings.username;
  home.enableNixpkgsReleaseCheck = false;

  home.stateVersion = "25.11"; # Please read the comment before changing.
  home.packages =
    fileManagerPackages
    ++ terminalPackages
    ++ editorPackages
    ++ collaborationPackages
    ++ workflowPackages;

  home.sessionVariables = {
    EDITOR = userSettings.editor;
    VISUAL = userSettings.editor;
    SPAWNEDITOR = userSettings.spawnEditor;
    BROWSER = userSettings.browser;
  };

  home.file.".Xdefaults".text = ''
    *.font: JetBrainsMono Nerd Font:pixelsize=16:antialias=true:autohint=true;
    *.fontalt0: JetBrainsMono Nerd Font:pixelsize=16:antialias=true:autohint=true;
    *.alpha: 0.9
  '';

  news.display = "silent";

  nix = {
    package = pkgs.nix;
    settings = {
      trusted-users = [userSettings.username];
      extra-substituters = ["https://cache.numtide.com"];
      extra-trusted-public-keys = [
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      ];
    };
  };

  programs.home-manager.enable = true;

  services.cachix-agent = {
    enable = true;
    # Match the Cachix Deploy agent name to this host's configured identity.
    name = systemSettings.hostname;
  };
}
