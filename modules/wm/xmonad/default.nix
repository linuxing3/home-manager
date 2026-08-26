{
  pkgs,
  lib,
  ...
}: let
  oxwmPkgs = import ../../shared/oxwm {inherit pkgs;};
  inherit (oxwmPkgs) oxwm-autostart;

  xmonadHs = pkgs.replaceVars ./xmonad.hs {
    xmobar = lib.getExe pkgs.xmobar;
    trayer = lib.getExe pkgs.trayer;
    keybinds = "${./keybinds.txt}";
  };

  xmonad-session = pkgs.writeShellApplication {
    name = "xmonad-session";
    runtimeInputs = with pkgs; [
      xmonad-with-packages
      xmobar
      trayer
      dmenu
      feh
      less
      xrdb
      xrandr
      xsetroot
      ncurses
      dbus
      systemd
      oxwm-autostart
    ];
    text = builtins.readFile ./xmonad-session.sh;
  };

  xmonad-nested = pkgs.writeShellApplication {
    name = "xmonad-nested";
    runtimeInputs = with pkgs; [
      coreutils
      procps
      xmonad-with-packages
      xorg-server
      xrdb
      xsetroot
    ];
    text = ''
      display="''${1:-:8}"
      if [[ -e /tmp/.X''${display#:}-lock ]] || [[ -e /tmp/.X11-unix/X''${display#:} ]]; then
        echo "xmonad-nested: display $display is already in use" >&2
        exit 1
      fi
      Xephyr "$display" -screen 1440x900 -resizeable -title xmonad-nested &
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
      exec xmonad
    '';
  };
in {
  home.packages = [
    pkgs.xmonad-with-packages
    pkgs.xmobar
    pkgs.trayer
    pkgs.dmenu
    pkgs.less
    xmonad-session
    xmonad-nested
  ];

  xdg.configFile."xmonad/xmonad.hs".source = xmonadHs;
  xdg.configFile."xmobar/xmobarrc".source = ./xmobarrc;
  xdg.configFile."xmonad/keybinds.txt".source = ./keybinds.txt;

  home.file.".local/share/xsessions/xmonad.desktop".text = ''
    [Desktop Entry]
    Name=xmonad
    Comment=xmonad (oxwm keybinds and colors)
    Exec=${lib.getExe xmonad-session}
    TryExec=${lib.getExe xmonad-session}
    Type=Application
    DesktopNames=xmonad
    X-LightDM-DesktopName=xmonad
  '';

  home.activation.compileXmonad = lib.hm.dag.entryAfter ["linkGeneration"] ''
    mkdir -p "$HOME/.cache/xmonad" "$HOME/.local/share/xmonad"
    export PATH="${lib.makeBinPath [pkgs.xmonad-with-packages pkgs.coreutils pkgs.gnugrep pkgs.gnused]}:$PATH"
    xmonad --recompile
  '';
}
