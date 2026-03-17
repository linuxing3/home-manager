{ lib, userSettings, ... }:

let
  themePolarity = lib.removeSuffix "\n" (builtins.readFile (./. + "/../../themes"+("/"+userSettings.theme)+"/polarity.txt"));
  myLightDMTheme = if themePolarity == "light" then "Adwaita" else "Adwaita-dark";
in
{
  stylix.targets.console.enable = true;

  stylix.targets.lightdm.enable = true;
  services.xserver.displayManager.lightdm = {
    enable = true;
    greeters.slick.enable = true;
    greeters.slick.theme.name = myLightDMTheme;
  };

}
