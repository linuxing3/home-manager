{
  pkgs,
  lib,
  ...
}: let
  oxwmPkgs = import ../../shared/oxwm {inherit pkgs;};
  inherit (oxwmPkgs) oxwm-autostart;

  emacsWithExwm = pkgs.emacs.pkgs.withPackages (epkgs: [
    epkgs.exwm
    epkgs.doom-themes
  ]);

  exwm-session = pkgs.writeShellApplication {
    name = "exwm-session";
    runtimeInputs = with pkgs; [
      emacsWithExwm
      st
      coreutils
      procps
      xrdb
      xrandr
      xsetroot
      dbus
      systemd
      ncurses
      kbd
      feh
      dmenu
      trayer
      oxwm-autostart
    ];
    runtimeEnv = {
      EXWM_INIT_EL = "${./exwm-init.el}";
    };
    text = builtins.readFile ./exwm-session.sh;
  };

  exwm-nested = pkgs.writeShellApplication {
    name = "exwm-nested";
    runtimeInputs = with pkgs; [
      coreutils
      procps
      emacsWithExwm
      xorg-server
      xrdb
      xsetroot
    ];
    runtimeEnv = {
      EXWM_INIT_EL = "${./exwm-init.el}";
    };
    text = ''
      display="''${1:-:8}"
      if [[ -e /tmp/.X''${display#:}-lock ]] || [[ -e /tmp/.X11-unix/X''${display#:} ]]; then
        echo "exwm-nested: display $display is already in use" >&2
        exit 1
      fi
      Xephyr "$display" -screen 1440x900 -resizeable -title exwm-nested &
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
      export EXWM_ENABLE=1
      if [[ -n "''${EXWM_INIT_EL:-}" ]] && [[ -f "''${EXWM_INIT_EL}" ]]; then
        exec emacs -l "''${EXWM_INIT_EL}"
      elif [[ -f "''${HOME}/.config/exwm/exwm-init.el" ]]; then
        exec emacs -l "''${HOME}/.config/exwm/exwm-init.el"
      else
        exec emacs --eval "(progn (require 'exwm) (if (fboundp 'exwm-enable) (exwm-enable) (when (fboundp 'exwm-wm-mode) (exwm-wm-mode 1))))"
      fi
    '';
  };
in {
  home.packages = [
    # Session wrappers already wrap emacsWithExwm; putting it on PATH collides
    # with programs.doom-emacs (both ship bin/ctags).
    exwm-session
    exwm-nested
    pkgs.dmenu
    pkgs.trayer
    pkgs.less
  ];

  xdg.configFile."exwm/keybinds.txt".source = ./keybinds.txt;
  xdg.configFile."exwm/exwm-init.el".source = ./exwm-init.el;

  home.file.".local/share/xsessions/exwm.desktop".text = ''
    [Desktop Entry]
    Name=EXWM
    Comment=Emacs X Window Manager
    Exec=${lib.getExe exwm-session}
    TryExec=${lib.getExe exwm-session}
    Type=Application
    DesktopNames=exwm
    X-LightDM-DesktopName=exwm
  '';
}
