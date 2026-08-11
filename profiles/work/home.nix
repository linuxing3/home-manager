{
  pkgs,
  userSettings,
  lib,
  ...
}: let
  baseImports = [
    # ------------- security -------------------
    ../../security/security.nix

    # ------------- cli -------------------
    ../../modules/shell/sh.nix
    ../../modules/shell/cli-collection.nix
    ../../modules/app/git/git.nix
    ../../modules/app/ranger/ranger.nix
    ../../modules/app/agent-tools/default.nix
    ../../modules/tui/nnn-herdr-sync.nix

    # ------------- editor -------------------
    ../../modules/app/nvim/nvim.nix

    # ------------- app -------------------
    ../../modules/app/cli-proxy-api/default.nix
    ../../modules/app/rclone/default.nix

    # ------------- wm/gui -------------------
    ../../modules/wm/oxwm/oxwm.nix
  ];
  crabboxPackage = pkgs.buildGoModule {
    pname = "crabbox";
    version = "0.22.1-e73b02f";
    src = pkgs.fetchFromGitHub {
      owner = "openclaw";
      repo = "crabbox";
      rev = "e73b02f6455f0e41c35c5a1b4f0dab3e65911005";
      hash = "sha256-JErrI5TU3BlVsYyH1NELkO14ct5J5AjdKP2B1aghFFw=";
    };
    vendorHash = "sha256-963ZX9X5extYKc9KaKkiX/mI5u4F5uoZPcHPWXAO/Hk=";
    subPackages = ["cmd/crabbox"];
    env.CGO_ENABLED = 0;
    ldflags = [
      "-s"
      "-w"
      "-X github.com/openclaw/crabbox/internal/cli.version=0.22.1-e73b02f"
    ];
  };
  fileManagerPackages = with pkgs; [
    yazi
    nnn
  ];
  terminalPackages = with pkgs; [
    dwm
    st
    tabbed
  ];
  editorPackages = with pkgs; [helix];
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
    crabboxPackage
  ];
  networkPackages = with pkgs; [
    cloudflared
    cloudflare-warp
    tailscale
    wrangler
  ];
  browserRuntimePackages = with pkgs; [
    bun
    chromium
  ];
  termscopeRuntimePackages = with pkgs; [
    python3
    television
  ];
  desktopMediaPackages = with pkgs; [
    zathura
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

  my.features.home.nvim = true;

  home.stateVersion = "25.11"; # Please read the comment before changing.
  home.packages =
    fileManagerPackages
    ++ terminalPackages
    ++ editorPackages
    ++ collaborationPackages
    ++ workflowPackages
    ++ networkPackages
    ++ browserRuntimePackages
    ++ desktopMediaPackages
    ++ termscopeRuntimePackages;

  home.sessionVariables = {
    EDITOR = userSettings.editor;
    VISUAL = userSettings.editor;
    SPAWNEDITOR = userSettings.spawnEditor;
    AI_BROWSER = lib.getExe pkgs.agent-browser;
    AGENT_BROWSER = lib.getExe pkgs.agent-browser;
    BROWSER = userSettings.browser;
  };

  home.file.".Xdefaults".text = ''
    *.font: JetBrainsMono Nerd Font:pixelsize=16:antialias=true:autohint=true;
    *.fontalt0: JetBrainsMono Nerd Font:pixelsize=16:antialias=true:autohint=true;
    *.alpha: 0.9
  '';

  home.file.".xsessionrc".text = ''
    ${pkgs.xrdb}/bin/xrdb -merge "$HOME/.Xdefaults"
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
}
