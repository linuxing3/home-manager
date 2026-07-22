{
  config,
  lib,
  pkgs,
  userSettings,
}: {fontSizes}: let
  themesDir = ../../themes;
  themeDir = themesDir + "/${userSettings.theme}";
  themePath = themeDir + "/${userSettings.theme}.yaml";
  themePolarity = lib.removeSuffix "\n" (builtins.readFile (themeDir + "/polarity.txt"));
  backgroundUrl = builtins.readFile (themeDir + "/backgroundurl.txt");
  backgroundSha256 = builtins.readFile (themeDir + "/backgroundsha256.txt");
in {
  home.file.".currenttheme".text = userSettings.theme;

  stylix.autoEnable = false;
  stylix.polarity = themePolarity;
  stylix.image = pkgs.fetchurl {
    url = backgroundUrl;
    sha256 = backgroundSha256;
  };
  stylix.base16Scheme = themePath;

  stylix.fonts = {
    monospace = {
      name = userSettings.font;
      package = userSettings.fontPkg;
    };
    serif = {
      name = userSettings.font;
      package = userSettings.fontPkg;
    };
    sansSerif = {
      name = userSettings.font;
      package = userSettings.fontPkg;
    };
    emoji = {
      name = "Noto Emoji";
      package = pkgs.noto-fonts-monochrome-emoji;
    };
    sizes = fontSizes;
  };

  fonts.fontconfig.defaultFonts = {
    monospace = [userSettings.font];
    sansSerif = [userSettings.font];
    serif = [userSettings.font];
  };

  stylix.targets.kitty.enable = true;
  stylix.targets.gtk.enable = true;
  stylix.targets.rofi.enable = userSettings.wmType == "x11";
  stylix.targets.feh.enable = userSettings.wmType == "x11";

  home.file.".fehbg-stylix" = {
    text = ''
      #!/bin/sh
      feh --no-fehbg --bg-fill ${config.stylix.image};
    '';
    executable = true;
  };

  home.file.".config/hypr/hyprpaper.conf".text = ''
    preload = ${config.stylix.image}
    wallpaper = ,${config.stylix.image}
  '';
}
