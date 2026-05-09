{
  pkgs,
  inputs,
  userSettings,
  systemSettings,
  lib,
  ...
}:
let
  features = import ../../nix/features.nix;
  moduleToggles = features.profiles.work.home;
  baseImports = [
    # ------------- security -------------------
    ../../security/security.nix

    # ------------- style -------------------
    ../../modules/gui/stylix.nix

    # ------------- cli -------------------
    ../../modules/shell/sh.nix
    ../../modules/shell/cli-collection.nix
    ../../modules/app/git/git.nix
    ../../modules/app/ranger/ranger.nix

    # ------------- editor -------------------
    ../../modules/app/nixvim

    # ------------- app -------------------
    ../../modules/app/mail/default.nix
    ../../modules/app/hermes/default.nix
    ../../modules/app/hermes-python-tools/default.nix
    ../../modules/app/playwright/default.nix
    ../../modules/app/rclone/default.nix

    # ------------- wm/gui -------------------
    ../../modules/gui/fuzzel.nix
    ../../modules/wm/oxwm/oxwm.nix
  ];
  featureModules = [
    ../../modules/tui/kitty.nix
    ../../modules/tui/ghostty.nix
    ../../modules/tui/wezterm.nix
    ../../modules/tui/warp.nix
    ../../modules/tui/zellij.nix
    ../../modules/tui/tmux.nix
    ../../modules/app/nvim/nvim.nix
    ../../modules/app/doom-emacs/doom-slim.nix
    ../../modules/lang/python/python-extra.nix
    ../../modules/lang/rust/rust.nix
    ../../modules/lang/nodejs/nodejs.nix
    ../../modules/lang/cc/cc.nix
    ../../modules/lang/gl/gl.nix
    ../../modules/app/browser/chrome.nix
    ../../modules/app/browser/qutebrowser.nix
    ../../modules/app/browser/brave.nix
    ../../modules/wm/hyprland/hyprland.nix
    ../../modules/wm/sway/sway.nix
    ../../modules/wm/i3/i3.nix
    ../../modules/app/virtualization/virtualization.nix
  ];
  fileManagerPackages = with pkgs; [
    yazi
    nnn
  ];
  terminalPackages = with pkgs; [
    st
    dwm
  ];
  editorPackages = with pkgs; [
    helix-steel-system
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
in
{
  imports = baseImports ++ featureModules;

  home.username = userSettings.username;
  home.homeDirectory = "/home/" + userSettings.username;
  home.enableNixpkgsReleaseCheck = false;

  home.stateVersion = "25.11"; # Please read the comment before changing.
  home.packages =
    fileManagerPackages
    ++ terminalPackages
    ++ editorPackages
    ++ collaborationPackages
    ++ workflowPackages
    ++ desktopMediaPackages;

  home.nixvim.enable = true;

  # Clear the old agent-browser executable override workaround. The package now
  # defaults to the native Lightpanda engine, so keeping a browser-specific
  # executablePath here forces stale Chrome/Brave launch behavior.
  home.file.".agent-browser/config.json".text = builtins.toJSON { };

  home.sessionVariables = {
    TERM = "xterm-256color";
    EDITOR = userSettings.editor;
    VISUAL = userSettings.editor;
    SPAWNEDITOR = userSettings.spawnEditor;
    BROWSER = userSettings.browser;
    GOG_ACCOUNT = userSettings.emailAlt;

    # Agent browser runtime paths on Nix (avoid glibc/loader lookup issues)
    AGENT_BROWSER_ENGINE = "lightpanda";
  };

  news.display = "silent";

  programs.home-manager.enable = true;

  my.features.home = {
    kitty = moduleToggles.kitty;
    ghostty = moduleToggles.ghostty;
    wezterm = moduleToggles.wezterm;
    warp = moduleToggles.warp;
    zellij = moduleToggles.zellij;
    tmux = moduleToggles.tmux;
    nvim = moduleToggles.nvim;
    doom = moduleToggles.doom;
    pythonExtra = moduleToggles.pythonExtra;
    rust = moduleToggles.rust;
    nodejs = moduleToggles.nodejs;
    cc = moduleToggles.cc;
    gl = moduleToggles.gl;
    chrome = moduleToggles.chrome;
    qutebrowser = moduleToggles.qutebrowser;
    brave = moduleToggles.brave;
    hyprland = moduleToggles.hyprland;
    sway = moduleToggles.sway;
    i3 = moduleToggles.i3;
    virtualization = moduleToggles.virtualization;
  };

  services.cachix-agent = {
    enable = true;
    # Match the Cachix Deploy agent name to this host's configured identity.
    name = systemSettings.hostname;
  };
}
