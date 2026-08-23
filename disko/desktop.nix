{
  lib,
  pkgs,
  userSettings,
  ...
}: let
  screenshot-to-clipboard = pkgs.writeShellApplication {
    name = "screenshot-to-clipboard";
    runtimeInputs = with pkgs; [maim xclip];
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
    text = builtins.readFile ../modules/wm/oxwm/autostart.sh;
  };
  oxwm-session = pkgs.writeShellApplication {
    name = "oxwm-session";
    runtimeInputs = with pkgs; [oxwm xorg.xrdb ncurses];
    text = builtins.readFile ../modules/wm/oxwm/oxwm-session.sh;
  };
  gruvbox = ../themes/gruvbox-dark-medium;
  wallpaper = pkgs.fetchurl {
    url = lib.removeSuffix "\n" (builtins.readFile (gruvbox + "/backgroundurl.txt"));
    sha256 = lib.removeSuffix "\n" (builtins.readFile (gruvbox + "/backgroundsha256.txt"));
  };
in {
  stylix.enable = true;
  stylix.autoEnable = false;
  stylix.homeManagerIntegration.autoImport = false;
  stylix.polarity = lib.removeSuffix "\n" (builtins.readFile (gruvbox + "/polarity.txt"));
  stylix.base16Scheme = gruvbox + "/gruvbox-dark-medium.yaml";
  stylix.image = wallpaper;
  stylix.fonts = {
    monospace = {
      name = "JetBrainsMono Nerd Font";
      package = pkgs.nerd-fonts.jetbrains-mono;
    };
    sansSerif = {
      name = "JetBrainsMono Nerd Font";
      package = pkgs.nerd-fonts.jetbrains-mono;
    };
    serif = {
      name = "JetBrainsMono Nerd Font";
      package = pkgs.nerd-fonts.jetbrains-mono;
    };
    emoji = {
      name = "Noto Emoji";
      package = pkgs.noto-fonts-monochrome-emoji;
    };
  };
  stylix.targets.gtk.enable = true;
  stylix.targets.grub.enable = true;
  stylix.targets.grub.useWallpaper = true;

  fonts.fontconfig.enable = true;
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    noto-fonts-cjk-sans
    noto-fonts-monochrome-emoji
    source-han-sans
  ];

  programs.dconf.enable = true;
  services.libinput.enable = true;
  services.libinput.mouse.leftHanded = true;
  services.libinput.touchpad.leftHanded = true;

  services.xserver.enable = true;
  # Manual startx after getty autologin (no display manager race).
  services.xserver.autorun = false;
  services.xserver.displayManager.startx.enable = true;
  services.xserver.displayManager.lightdm.enable = false;

  # Autologin every VT; shell profile starts X only on tty1.
  services.getty.autologinUser = userSettings.username;

  systemd.services."getty@tty1" = {
    overrideStrategy = "asDropin";
    unitConfig = {
      Before = [
        "display-manager.service"
        "accounts-daemon.service"
      ];
    };
  };

  environment.etc."profile.d/zz-startx-tty1.sh".text = ''
    if [ -z "''${DISPLAY:-}" ] && [ "''${XDG_VTNR:-}" = "1" ]; then
      exec startx
    fi
  '';

  environment.etc."X11/xinit/xinitrc".text = ''
    #!/bin/sh
    mkdir -p "$HOME/.config/oxwm"
    ln -sfn /etc/oxwm/config.lua "$HOME/.config/oxwm/config.lua"
    ${pkgs.xrdb}/bin/xrdb -merge "$HOME/.Xresources" || true
    ${pkgs.xrdb}/bin/xrdb -merge "$HOME/.Xdefaults" || true
    ${lib.getExe oxwm-autostart} &
    exec ${lib.getExe pkgs.oxwm}
  '';

  environment.etc."oxwm/config.lua".source = ../modules/wm/oxwm/config.lua;
  environment.sessionVariables.TERMINFO_DIRS = "${pkgs.ncurses}/share/terminfo\${TERMINFO_DIRS:+:}$TERMINFO_DIRS";

  environment.systemPackages = with pkgs; [
    oxwm
    dmenu
    st
    maim
    xclip
    xrdb
    xsetroot
    feh
    brave
    pasystray
    ncurses
    screenshot-to-clipboard
    oxwm-autostart
    oxwm-session
  ];
}
