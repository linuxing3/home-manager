{ config, lib, pkgs, userSettings, ... }:

let
  themePath = "/../../themes"+("/"+userSettings.theme+"/"+userSettings.theme)+".yaml";
  themePolarity = lib.removeSuffix "\n" (builtins.readFile (./. + "/../../themes"+("/"+userSettings.theme)+"/polarity.txt"));
  backgroundUrl = builtins.readFile (./. + "/../../themes"+("/"+userSettings.theme)+"/backgroundurl.txt");
  backgroundSha256 = builtins.readFile (./. + "/../../themes/"+("/"+userSettings.theme)+"/backgroundsha256.txt");
in
{

  home.file.".currenttheme".text = userSettings.theme;
  stylix.autoEnable = false;
  stylix.polarity = themePolarity;
  stylix.image = pkgs.fetchurl {
    url = backgroundUrl;
    sha256 = backgroundSha256;
  };
  stylix.base16Scheme = ./. + themePath;

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
    sizes = {
      terminal = 16;
      applications = 14;
      popups = 14;
      desktop = 14;
    };
  };

  stylix.targets.kitty.enable = true;
  stylix.targets.gtk.enable = true;
  stylix.targets.rofi.enable = if (userSettings.wmType == "x11") then true else false;

  stylix.targets.feh.enable = if (userSettings.wmType == "x11") then true else false;

  home.file.".fehbg-stylix".text = ''
    #!/bin/sh
    feh --no-fehbg --bg-fill ''+config.stylix.image+'';
  '';
  home.file.".fehbg-stylix".executable = true;

  home.file.".config/hypr/hyprpaper.conf".text = ''
    preload = ''+config.stylix.image+''

    wallpaper = ,''+config.stylix.image+''
  '';
}
