{
  pkgs,
  inputs,
  userSettings,
  systemSettings,
  lib,
  ...
}: let
  sidexRuntimeLibs = with pkgs; [
    stdenv.cc.cc
    stdenv.cc
    zlib
    openssl
    glib
    gtk3
    webkitgtk_4_1
    libsoup_3
    libxkbcommon
  ];
  sidexRuntimeLibPath = lib.makeLibraryPath sidexRuntimeLibs;
  moduleToggles = {
    kitty = false;
    zellij = false;
    tmux = true;
    nvim = false;
    doom = false;
    pythonExtra = false;
    rust = false;
    nodejs = false;
    cc = false;
    gl = false;
    qutebrowser = false;
    brave = false;
    hyprland = false;
    sway = false;
    i3 = false;
    chineseIbus = false;
    nihongo = false;
    virtualization = false;
  };
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

    # ------------- wm/gui -------------------
    ../../modules/gui/fuzzel.nix
    ../../modules/wm/xmonad/xmonad.nix
  ];
  optionalImports =
    []
    ++ lib.optionals moduleToggles.kitty [../../modules/tui/kitty.nix]
    ++ lib.optionals moduleToggles.zellij [../../modules/tui/zellij.nix]
    ++ lib.optionals moduleToggles.tmux [../../modules/tui/tmux.nix]
    ++ lib.optionals moduleToggles.nvim [../../modules/app/nvim/nvim.nix]
    ++ lib.optionals moduleToggles.doom [../../modules/app/doom-emacs/doom-slim.nix]
    ++ lib.optionals moduleToggles.pythonExtra [../../modules/lang/python/python-extra.nix]
    ++ lib.optionals moduleToggles.rust [../../modules/lang/rust/rust.nix]
    ++ lib.optionals moduleToggles.nodejs [../../modules/lang/nodejs/nodejs.nix]
    ++ lib.optionals moduleToggles.cc [../../modules/lang/cc/cc.nix]
    ++ lib.optionals moduleToggles.gl [../../modules/lang/gl/gl.nix]
    ++ lib.optionals moduleToggles.qutebrowser [../../modules/app/browser/qutebrowser.nix]
    ++ lib.optionals moduleToggles.brave [../../modules/app/browser/brave.nix]
    ++ lib.optionals moduleToggles.hyprland [../../modules/wm/hyprland/hyprland.nix]
    ++ lib.optionals moduleToggles.sway [../../modules/wm/sway/sway.nix]
    ++ lib.optionals moduleToggles.i3 [../../modules/wm/i3/i3.nix]
    ++ lib.optionals moduleToggles.chineseIbus [../../modules/wm/input/chinese-ibus.nix]
    ++ lib.optionals moduleToggles.nihongo [../../modules/wm/input/nihongo.nix]
    ++ lib.optionals moduleToggles.virtualization [../../modules/app/virtualization/virtualization.nix];
  fileManagerPackages = with pkgs; [
    yazi
    nnn
  ];
  terminalPackages = with pkgs; [
    st
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
    nautilus
    pcmanfm
    imv
    sxiv
    nsxiv
    vlc
    mpv
    viu
  ];
  agentPackages = [
    inputs.hermes-agent.packages.${pkgs.system}.default
  ];
  sidexRuntimePackages = with pkgs; [
    rustc
    cargo
    pkg-config
    gobject-introspection
    cairo
    pango
    atk
    gtk3
    webkitgtk_4_1
    libsoup_3
    glib
    openssl
    zlib
  ];
in {
  imports = baseImports ++ optionalImports;

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
    ++ desktopMediaPackages
    ++ agentPackages
    ++ sidexRuntimePackages;

  home.nixvim.enable = true;

  home.sessionVariables = {
    TERM = "xterm-256color";
    EDITOR = userSettings.editor;
    VISUAL = userSettings.editor;
    SPAWNEDITOR = userSettings.spawnEditor;
    BROWSER = userSettings.browser;
    GOG_ACCOUNT = userSettings.emailAlt;

    # Agent browser runtime paths on Nix (avoid glibc/loader lookup issues)
    PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";

    # SideX runtime linker paths on Nix (GLIBC/WebKitGTK)
    LD_LIBRARY_PATH = sidexRuntimeLibPath;
    NIX_LD_LIBRARY_PATH = sidexRuntimeLibPath;
    NIX_LD = pkgs.stdenv.cc.bintools.dynamicLinker;
  };

  news.display = "silent";

  programs.home-manager.enable = true;

  services.cachix-agent = {
    enable = true;
    # Match the Cachix Deploy agent name to this host's configured identity.
    name = systemSettings.hostname;
  };
}
