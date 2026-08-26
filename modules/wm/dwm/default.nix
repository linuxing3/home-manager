{
  pkgs,
  lib,
  ...
}: let
  oxwmPkgs = import ../../shared/oxwm {inherit pkgs;};
  inherit (oxwmPkgs) oxwm-autostart;

  dwm-status = pkgs.writeShellApplication {
    name = "dwm-status";
    runtimeInputs = with pkgs; [coreutils procps gawk xsetroot];
    text = builtins.readFile ./dwm-status.sh;
  };

  dwm-session = pkgs.writeShellApplication {
    name = "dwm-session";
    runtimeInputs = with pkgs; [
      dwm
      dwm-status
      dmenu
      trayer
      feh
      less
      procps
      xrdb
      xrandr
      xsetroot
      ncurses
      dbus
      systemd
      oxwm-autostart
    ];
    text = builtins.readFile ./dwm-session.sh;
  };

  dwm-nested = pkgs.writeShellApplication {
    name = "dwm-nested";
    runtimeInputs = with pkgs; [
      coreutils
      procps
      dwm
      dwm-status
      xorg-server
      xrdb
      xsetroot
    ];
    text = ''
      display="''${1:-:8}"
      if [[ -e /tmp/.X''${display#:}-lock ]] || [[ -e /tmp/.X11-unix/X''${display#:} ]]; then
        echo "dwm-nested: display $display is already in use" >&2
        exit 1
      fi
      Xephyr "$display" -screen 1440x900 -resizeable -title dwm-nested &
      xephyr_pid=$!
      trap 'kill "$xephyr_pid" 2>/dev/null || true' EXIT
      for _ in $(seq 1 50); do
        if [[ -e /tmp/.X11-unix/X''${display#:} ]]; then
          break
        fi
        sleep 0.1
      done
      export DISPLAY="$display"
      export LANG="''${LANG:-C.UTF-8}"
      export LC_CTYPE="''${LC_CTYPE:-$LANG}"
      if [[ -f ''${HOME}/.Xresources ]]; then
        xrdb -merge "''${HOME}/.Xresources" || true
      fi
      if [[ -f ''${HOME}/.Xdefaults ]]; then
        xrdb -merge "''${HOME}/.Xdefaults" || true
      fi
      xsetroot -cursor_name left_ptr || true
      pkill -x dwm-status >/dev/null 2>&1 || true
      dwm-status >/dev/null 2>&1 &
      exec dwm
    '';
  };
in {
  home.packages = [
    pkgs.dwm
    pkgs.dmenu
    pkgs.trayer
    pkgs.less
    dwm-status
    dwm-session
    dwm-nested
  ];

  xdg.configFile."dwm/keybinds.txt".source = ./keybinds.txt;

  home.file.".local/share/xsessions/dwm.desktop".text = ''
    [Desktop Entry]
    Name=dwm
    Comment=dwm (oxwm keybinds and colors)
    Exec=${lib.getExe dwm-session}
    TryExec=${lib.getExe dwm-session}
    Type=Application
    DesktopNames=dwm
    X-LightDM-DesktopName=dwm
  '';
}
