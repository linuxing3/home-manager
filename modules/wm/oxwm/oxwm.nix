{
  pkgs,
  lib,
  ...
}: let
  oxwmPkgs = import ../../shared/oxwm {inherit pkgs;};
  inherit (oxwmPkgs) oxwm-session oxwm-autostart;
  screenshot-to-clipboard = pkgs.writeShellApplication {
    name = "screenshot-to-clipboard";
    runtimeInputs = with pkgs; [
      coreutils
      maim
      xclip
    ];
    text = ''
      maim --select | xclip -selection clipboard -target image/png -in
    '';
  };
  install-lightdm-oxwm = pkgs.writeShellApplication {
    name = "install-lightdm-oxwm";
    runtimeInputs = with pkgs; [
      coreutils
      gnused
      gnugrep
    ];
    text = builtins.readFile ./install-lightdm-oxwm.sh;
  };
  install-startx-autologin = pkgs.writeShellApplication {
    name = "install-startx-autologin";
    runtimeInputs = with pkgs; [
      coreutils
      gnugrep
    ];
    text = builtins.readFile ./install-startx-autologin.sh;
  };
  # greetd owns tty1 (nixos/greetd.nix). Do not exec startx from login
  # shells: that always uses ~/.xinitrc (oxwm) and ignores the greeter.
in {
  imports = [
    ../input/chinese-sogou.nix
  ];

  home.packages = with pkgs; [
    oxwm
    dmenu
    feh
    pasystray
    pavucontrol
    at-spi2-core
    ncurses
    screenshot-to-clipboard
    oxwm-autostart
    oxwm-session
    install-lightdm-oxwm
    install-startx-autologin
  ];

  # Host terminfo often lacks st-256color; point clients at Nix ncurses.
  home.sessionVariables.TERMINFO_DIRS = lib.mkDefault "${pkgs.ncurses}/share/terminfo\${TERMINFO_DIRS:+:}$TERMINFO_DIRS";

  home.file.".config/oxwm/config.lua" = {
    source = oxwmPkgs.configLua;
    force = true;
  };
  # Store path, not ~/.local/bin: Cursor Agent rewrites that directory and
  # would leave startx exec'ing a missing oxwm-session (getty start-limit-hit).
  home.file.".local/share/xsessions/oxwm.desktop".text = ''
    [Desktop Entry]
    Name=oxwm
    Comment=OXWM dynamic window manager
    Exec=${lib.getExe oxwm-session}
    TryExec=${lib.getExe oxwm-session}
    Type=Application
    DesktopNames=oxwm
    X-LightDM-DesktopName=oxwm
  '';
  home.file.".dmrc".text = ''
    [Desktop]
    Session=oxwm
  '';

  # Bare `startx` fallback. greetd X11 sessions set XINITRC / wrap with
  # `startx env <session>` and do not use this file.
  home.file.".xinitrc".text = ''
    #!/bin/sh
    exec ${lib.getExe oxwm-session}
  '';

  # Ensure ~/.terminfo has st-256color even when TERMINFO_DIRS is ignored.
  home.activation.installStTerminfo = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p "$HOME/.terminfo"
    if [[ -f ${pkgs.ncurses}/share/terminfo/s/st-256color ]]; then
      mkdir -p "$HOME/.terminfo/s"
      cp -f ${pkgs.ncurses}/share/terminfo/s/st-256color "$HOME/.terminfo/s/st-256color"
      cp -f ${pkgs.ncurses}/share/terminfo/s/st "$HOME/.terminfo/s/st" 2>/dev/null || true
    fi
  '';
}
