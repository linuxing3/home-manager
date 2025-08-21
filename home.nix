{ config, pkgs, userSettings, ... }:

{

  imports = [
    ./modules/gui/stylix.nix

    ./modules/wm/hyprland/hyprland.nix
    ./modules/gui/waybar.nix

    ./modules/app/ranger/ranger.nix
    ./modules/tui/zellij.nix
    ./modules/tui/tmux.nix
    ./modules/tui/kitty.nix
    ./modules/tui/alacritty.nix

    ./modules/editor/nvim.nix
  ];

  home.username = userSettings.username;
  home.homeDirectory = "/home/" + userSettings.username;

  home.stateVersion = "25.05"; # Please read the comment before changing.
  home.packages = with pkgs; [
    gh
    git
    lazygit

    helix

    zellij
    tmux

    nnn

    cachix

    # Media
    gimp
    vlc
    mpv

    # launcher
    wofi
    rofi
    xmobar
    lxterminal
  ];

  xdg.enable = true;
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    music = "${config.home.homeDirectory}/Media/Music";
    videos = "${config.home.homeDirectory}/Media/Videos";
    pictures = "${config.home.homeDirectory}/Media/Pictures";
    templates = "${config.home.homeDirectory}/Templates";
    download = "${config.home.homeDirectory}/Downloads";
    documents = "${config.home.homeDirectory}/Documents";
    desktop = null;
    publicShare = null;
    extraConfig = {
      XDG_DOTFILES_DIR = "${config.home.homeDirectory}/.dotfiles";
      XDG_ARCHIVE_DIR = "${config.home.homeDirectory}/Archive";
      XDG_VM_DIR = "${config.home.homeDirectory}/Machines";
      XDG_ORG_DIR = "${config.home.homeDirectory}/Org";
      XDG_PODCAST_DIR = "${config.home.homeDirectory}/Media/Podcasts";
      XDG_BOOK_DIR = "${config.home.homeDirectory}/Media/Books";
    };
  };
  xdg.mime.enable = true;
  xdg.mimeApps.enable = true;
  xdg.mimeApps.associations.added = {
    # TODO fix mime associations, most of them are totally broken :(
    "application/octet-stream" = "flstudio.desktop;";
    "x-scheme-handler/org-protocol" = "org-protocol.desktop;";
  };

  home.sessionVariables = {
    EDITOR = userSettings.editor;
    SPAWNEDITOR = userSettings.spawnEditor;
    TERM = userSettings.term;
    BROWSER = userSettings.browser;
  };

  news.display = "silent";

  gtk.iconTheme = {
    package = pkgs.papirus-icon-theme;
    name =
      if (config.stylix.polarity == "dark")
      then "Papirus-Dark"
      else "Papirus-Light";
  };

  services.pasystray.enable = true;

  programs.home-manager.enable = true;

  programs.doom-emacs = {
    enable = true;
    doomDir = ./uni-dotfiles/doom;
  };
}
