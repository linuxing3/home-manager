# Shared oxwm wrappers. Home Manager and NixOS both import this package set.
# Do not put home.* or services.xserver options here.
{pkgs}: {
  configLua = ./config.lua;

  oxwm-autostart = pkgs.writeShellApplication {
    name = "oxwm-autostart";
    runtimeInputs = with pkgs; [
      pasystray
      procps
      which
      xorg.xinput
      xorg.xmodmap
      xrandr
      xsetroot
      gnugrep
      gnused
      coreutils
      at-spi2-core
      pavucontrol
    ];
    text = builtins.readFile ./autostart.sh;
  };

  oxwm-session = pkgs.writeShellApplication {
    name = "oxwm-session";
    runtimeInputs = with pkgs; [
      oxwm
      xorg.xrdb
      xrandr
      xsetroot
      ncurses
      kbd
      dbus
      systemd
    ];
    text = builtins.readFile ./oxwm-session.sh;
  };
}
