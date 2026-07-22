{
  config,
  lib,
  pkgs,
  inputs,
  userSettings,
  ...
}: let
  stylixCommon = import ./stylix-common.nix {
    inherit config lib pkgs userSettings;
  };
in
  lib.mkMerge [
    {
      imports = [inputs.stylix.homeManagerModules.stylix];
    }
    (stylixCommon {
      fontSizes = {
        terminal = 18;
        applications = 12;
        popups = 12;
        desktop = 12;
      };
    })
    {
      stylix.targets.alacritty.enable = false;
      programs.alacritty.settings = {
        colors = {
          # TODO revisit these color mappings
          # these are just the default provided from stylix
          # but declared directly due to alacritty v3.0 breakage
          primary.background = "#" + config.lib.stylix.colors.base00;
          primary.foreground = "#" + config.lib.stylix.colors.base07;
          cursor.text = "#" + config.lib.stylix.colors.base00;
          cursor.cursor = "#" + config.lib.stylix.colors.base07;
          normal.black = "#" + config.lib.stylix.colors.base00;
          normal.red = "#" + config.lib.stylix.colors.base08;
          normal.green = "#" + config.lib.stylix.colors.base0B;
          normal.yellow = "#" + config.lib.stylix.colors.base0A;
          normal.blue = "#" + config.lib.stylix.colors.base0D;
          normal.magenta = "#" + config.lib.stylix.colors.base0E;
          normal.cyan = "#" + config.lib.stylix.colors.base0B;
          normal.white = "#" + config.lib.stylix.colors.base05;
          bright.black = "#" + config.lib.stylix.colors.base03;
          bright.red = "#" + config.lib.stylix.colors.base09;
          bright.green = "#" + config.lib.stylix.colors.base01;
          bright.yellow = "#" + config.lib.stylix.colors.base02;
          bright.blue = "#" + config.lib.stylix.colors.base04;
          bright.magenta = "#" + config.lib.stylix.colors.base06;
          bright.cyan = "#" + config.lib.stylix.colors.base0F;
          bright.white = "#" + config.lib.stylix.colors.base07;
        };
        font.size = config.stylix.fonts.sizes.terminal;
        font.normal.family = userSettings.font;
      };

      programs.feh.enable = true;

      home.file = {
        ".config/qt5ct/colors/oomox-current.conf".source = config.lib.stylix.colors {
          template = builtins.readFile ./oomox-current.conf.mustache;
          extension = ".conf";
        };
        ".config/Trolltech.conf".source = config.lib.stylix.colors {
          template = builtins.readFile ./Trolltech.conf.mustache;
          extension = ".conf";
        };
        ".config/kdeglobals".source = config.lib.stylix.colors {
          template = builtins.readFile ./Trolltech.conf.mustache;
          extension = "";
        };
        ".config/qt5ct/qt5ct.conf".text = pkgs.lib.mkBefore (builtins.readFile ./qt5ct.conf);
      };

      home.packages = with pkgs; [
        libsForQt5.qt5ct
        libsForQt5.breeze-qt5
        libsForQt5.breeze-icons
        noto-fonts-monochrome-emoji
      ];

      qt = {
        enable = true;
        style.package = pkgs.libsForQt5.breeze-qt5;
        style.name = "breeze-dark";
        platformTheme = "kde";
      };
    }
  ]
