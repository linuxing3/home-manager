{
  pkgs,
  lib,
  config,
  ...
}: let
  screenshot-to-clipboard = pkgs.writeShellApplication {
    name = "screenshot-to-clipboard";
    runtimeInputs = with pkgs; [
      maim
      xclip
    ];
    text = ''
      maim --select | xclip -selection clipboard -target image/png -in
    '';
  };
  oxwm-autostart = pkgs.writeShellApplication {
    name = "oxwm-autostart";
    runtimeInputs = with pkgs; [
      pasystray
      procps
      which
      xorg.xinput
      xorg.xmodmap
      gnugrep
      gnused
      coreutils
    ];
    text = builtins.readFile ./autostart.sh;
  };
  oxwm-session = pkgs.writeShellApplication {
    name = "oxwm-session";
    runtimeInputs = with pkgs; [
      oxwm
      xorg.xrdb
      ncurses
    ];
    text = builtins.readFile ./oxwm-session.sh;
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
  # tty1 getty autologin → startx (before LightDM / AccountsService).
  startxOnTty1 = ''
    if [ -z "''${DISPLAY:-}" ] && [ "''${XDG_VTNR:-}" = "1" ]; then
      exec startx
    fi
  '';
in {
  imports = [
    ../input/chinese-sogou.nix
  ];

  home.packages = with pkgs; [
    oxwm
    dmenu
    feh
    pasystray
    ncurses
    screenshot-to-clipboard
    oxwm-autostart
    oxwm-session
    install-lightdm-oxwm
    install-startx-autologin
  ];

  # Host terminfo often lacks st-256color; point clients at Nix ncurses.
  home.sessionVariables.TERMINFO_DIRS = lib.mkDefault "${pkgs.ncurses}/share/terminfo\${TERMINFO_DIRS:+:}$TERMINFO_DIRS";

  home.file.".config/oxwm/config.lua".source = ./config.lua;
  home.file.".local/share/xsessions/oxwm.desktop".source = ./oxwm.desktop;
  home.file.".dmrc".text = ''
    [Desktop]
    Session=oxwm
  '';

  # startx entrypoint (preferred over LightDM on UOS).
  home.file.".xinitrc".text = ''
    #!/bin/sh
    exec "${config.home.homeDirectory}/.local/bin/oxwm-session"
  '';

  programs.bash.profileExtra = lib.mkAfter startxOnTty1;
  programs.zsh.loginExtra = lib.mkAfter startxOnTty1;

  # Keep a stable path for LightDM / startx Exec= lines.
  home.file.".local/bin/oxwm-session".source = "${oxwm-session}/bin/oxwm-session";
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
