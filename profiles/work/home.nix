{ pkgs, userSettings, ... }:

{

  imports = [
    # ------------- security -------------------
    ../../security/security.nix

    # ------------- style -------------------
    ../../modules/gui/stylix.nix

    # ------------- cli -------------------
    ../../modules/shell/sh.nix
    ../../modules/shell/cli-collection.nix
    ../../modules/app/git/git.nix
    ../../modules/app/ranger/ranger.nix

    # ------------- tui -------------------
    # ../../modules/tui/kitty.nix
    # ../../modules/tui/zellij.nix
    # ../../modules/tui/tmux.nix

    # ------------- editor -------------------
    # ../../modules/app/nvim/nvim.nix
    # ../../modules/app/doom-emacs/doom-slim.nix

    # ------------- lang -------------------
    # ../../modules/lang/python/python-extra.nix
    # ../../modules/lang/rust/rust.nix
    # ../../modules/lang/nodejs/nodejs.nix
    # ../../modules/lang/cc/cc.nix
    # ../../modules/lang/gl/gl.nix

    # ------------- app -------------------
    ../../modules/app/mail/default.nix
    # ../../modules/app/browser/qutebrowser.nix
    # ../../modules/app/browser/brave.nix

    # ------------- wm/gui -------------------
    # ../../modules/gui/waybar.nix
    ../../modules/gui/gui-collection.nix
    # ../../modules/wm/hyprland/hyprland.nix
    # ../../modules/wm/sway/sway.nix
    ../../modules/wm/xmonad/xmonad.nix
    # ../../modules/wm/i3/i3.nix

    # ------------- input -------------------
    # ../../modules/wm/input/chinese-ibus.nix
    # ../../modules/wm/input/nihongo.nix

    # ------------- virtualization -------------------
    # ../../modules/app/virtualization/virtualization.nix
  ];

  home.username = userSettings.username;
  home.homeDirectory = "/home/" + userSettings.username;

  home.stateVersion = "25.11"; # Please read the comment before changing.
  home.packages = with pkgs; [
    helix-steel-system

    yazi
    nnn

    st

    gh
    lazygit
    zellij
    tmux

    just
    comma
    # home-manager

  ];

  home.sessionVariables = {
    TERM = "xterm-256color";
    EDITOR = userSettings.editor;
    VISUAL = userSettings.editor;
    SPAWNEDITOR = userSettings.spawnEditor;
    BROWSER = userSettings.browser;
  };

  news.display = "silent";

  programs.home-manager.enable = true;

}
