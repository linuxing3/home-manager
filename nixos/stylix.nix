{ lib, pkgs, inputs, ... }:

let
  myLightDMTheme = if themePolarity == "light" then "Adwaita" else "Adwaita-dark";
in
{
  imports = [ inputs.stylix.nixosModules.stylix ];

  stylix.targets.lightdm.enable = true;
  services.xserver.displayManager.lightdm = {
      greeters.slick.enable = true;
      greeters.slick.theme.name = myLightDMTheme;
  };
  stylix.targets.console.enable = true;

}
