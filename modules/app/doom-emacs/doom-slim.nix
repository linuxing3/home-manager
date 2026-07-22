{
  config,
  lib,
  pkgs,
  userSettings,
  systemSettings,
  ...
}:
let
  cfg = config.my.features.home;
  themePolarity = lib.removeSuffix "\n" (
    builtins.readFile (./. + "../../../../themes" + ("/" + userSettings.theme) + "/polarity.txt")
  );
  dashboardLogo = ./. + "/nix-" + themePolarity + ".webp";
in
{
  options.my.features.home.doom = lib.mkEnableOption "Enable Doom Emacs module";

  config = lib.mkIf cfg.doom {
    # setting system variables with nix
    home.file.".config/doom/system-vars.el".text = ''
;;; ~/.config/doom/system-vars.el -*- lexical-binding: t; -*-
(setq user-full-name "'' + userSettings.name + '' ") ; name
(setq user-username "'' + userSettings.username + '' ") ; username
(setq user-mail-address "'' + userSettings.email + '' ") ; email
(setq user-home-directory "/home/'' + userSettings.username + '' ") ; absolute path to home directory as string
(setq user-default-roam-dir "'' + userSettings.defaultRoamDir + '' ") ; absolute path to home directory as string
(setq system-nix-profile "'' + systemSettings.profile + '' ") ; what profile am I using?
(setq system-wm-type "'' + userSettings.wmType + '' ") ; wayland or x11?
(setq doom-font (font-spec :family "'' + userSettings.font + '' " :size 20)) ; import font
(setq dotfiles-dir "'' + userSettings.dotfilesDir + '' ") ; import location of dotfiles directory
    '';

    # loading theme configured by nix
    home.file.".config/doom/themes/doom-stylix-theme.el".source = config.lib.stylix.colors {
      template = builtins.readFile ../../../configs/doom/themes/doom-stylix-theme.el.mustache;
      extension = ".el";
    };

    # loading logo by nix
    home.file.".config/doom/dashboard-logo.webp".source = dashboardLogo;

    # installing all packages
    home.packages = (
      with pkgs;
      [
        emacs-lsp-booster
        (pkgs.callPackage ./pkgs/org-analyzer.nix { })
        (pkgs.callPackage ../../pkgs/mw.nix { })

      ]
    );
  };
}
