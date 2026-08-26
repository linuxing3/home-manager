# greetd + tuigreet on tty1. Pick oxwm, xmonad, or dwm at login.
# Replaces getty autologin → startx. Serial getty on ttyAMA0 stays for recovery.
# Do not define systemd.services."getty@tty1" (nixpkgs#429775).
#
# X11-only: tuigreet --sessions is Wayland. X11 sessions are wrapped with
# `startx env <Exec>`. Exec must be the WM session script, not another startx,
# or ~/.xinitrc (oxwm) always wins.
{
  lib,
  pkgs,
  config,
  ...
}: let
  oxwmPkgs = import ../modules/shared/oxwm {inherit pkgs;};
  inherit (oxwmPkgs) oxwm-session oxwm-autostart;

  dwm-status = pkgs.writeShellApplication {
    name = "dwm-status";
    runtimeInputs = with pkgs; [coreutils procps gawk xsetroot];
    text = builtins.readFile ../modules/wm/dwm/dwm-status.sh;
  };

  xmonad-session = pkgs.writeShellApplication {
    name = "xmonad-session";
    runtimeInputs = with pkgs; [
      xmonad-with-packages
      xmobar
      trayer
      dmenu
      xrdb
      xrandr
      xsetroot
      dbus
      systemd
      ncurses
      oxwm-autostart
    ];
    text = builtins.readFile ../modules/wm/xmonad/xmonad-session.sh;
  };

  mkX11Desktop = {
    name,
    comment,
    session,
  }:
    pkgs.runCommand "${name}-desktop" {
      passthru.providedSessions = [name];
    } ''
      mkdir -p "$out/share/xsessions"
      cat > "$out/share/xsessions/${name}.desktop" <<EOF
      [Desktop Entry]
      Name=${name}
      Comment=${comment}
      Exec=${lib.getExe session}
      TryExec=${lib.getExe session}
      Type=Application
      DesktopNames=${name}
      EOF
    '';

  oxwmDesktop = mkX11Desktop {
    name = "oxwm";
    comment = "OXWM (X11)";
    session = oxwm-session;
  };
  xmonadDesktop = mkX11Desktop {
    name = "xmonad";
    comment = "xmonad (oxwm keybinds, X11)";
    session = xmonad-session;
  };

  dwm-session = pkgs.writeShellApplication {
    name = "dwm-session";
    runtimeInputs = with pkgs; [
      dwm
      dwm-status
      dmenu
      trayer
      procps
      xrdb
      xrandr
      xsetroot
      dbus
      systemd
      ncurses
      oxwm-autostart
    ];
    text = builtins.readFile ../modules/wm/dwm/dwm-session.sh;
  };

  dwmDesktop = mkX11Desktop {
    name = "dwm";
    comment = "dwm (oxwm keybinds, X11)";
    session = dwm-session;
  };

  sessionsRoot = config.services.displayManager.sessionData.desktops;
  xsessionWrapper = "${lib.getExe' pkgs.xinit "startx"} ${lib.getExe' pkgs.coreutils "env"}";

  tuigreet-greeter = pkgs.writeShellApplication {
    name = "tuigreet-greeter";
    runtimeInputs = [pkgs.tuigreet];
    text = ''
      exec tuigreet \
        --time \
        --remember \
        --remember-session \
        --asterisks \
        --greeting 'F3 selects oxwm / xmonad / dwm' \
        --xsessions ${sessionsRoot}/share/xsessions \
        --xsession-wrapper ${lib.escapeShellArg xsessionWrapper}
    '';
  };
in {
  services.greetd.enable = true;
  services.greetd.useTextGreeter = true;
  services.greetd.settings.default_session = {
    command = lib.getExe tuigreet-greeter;
    user = "greeter";
  };

  services.displayManager.sessionPackages = [
    oxwmDesktop
    xmonadDesktop
    dwmDesktop
  ];

  environment.systemPackages = [
    pkgs.tuigreet
    pkgs.xmonad-with-packages
    pkgs.dwm
    xmonad-session
    dwm-session
  ];
}
