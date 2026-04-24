{ lib, ... }:
{
  options.my.features.home.hyprland = lib.mkEnableOption "Enable Hyprland module";

  imports = [
    ({ config, pkgs, ... }:
      lib.mkIf config.my.features.home.hyprland (
        import ../../app/dmenu-scripts/networkmanager-dmenu.nix {
          inherit pkgs;
          dmenu_command = "fuzzel -d";
        }
      ))
    ({ config, lib, pkgs, ... }:
      lib.mkIf config.my.features.home.hyprland (
        import ./hyprprofiles/hyprprofiles.nix {
          inherit config lib pkgs;
          dmenuCmd = "fuzzel -d";
        }
      ))
    ./hyprland-core.nix
    ./hyprland-files.nix
    ./hyprland-launchers.nix
  ];
}
