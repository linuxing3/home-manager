{
  pkgs,
  userSettings,
  ...
}: let
  baseImports = [
    # ------------- security -------------------
    ../../security/security.nix

    # ------------- cli -------------------
    ../../modules/shell/sh.nix
    ../../modules/app/git/git.nix

    # ------------- editor -------------------
    ../../modules/app/nvim/nvim.nix
  ];
  fileManagerPackages = with pkgs; [
    yazi
    nnn
  ];
  terminalPackages = with pkgs; [
    st
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
  ];
  browserRuntimePackages = with pkgs; [
    bun
    chromium
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
    ++ browserRuntimePackages;

  home.file.".Xdefaults".text = ''
    *.font: JetBrainsMono Nerd Font:pixelsize=16:antialias=true:autohint=true;
    *.fontalt0: JetBrainsMono Nerd Font:pixelsize=16:antialias=true:autohint=true;
    *.alpha: 0.9
  '';

  home.file.".xsessionrc".text = ''
    ${pkgs.xrdb}/bin/xrdb -merge "$HOME/.Xdefaults"
  '';

  news.display = "silent";

  programs.home-manager.enable = true;
}
