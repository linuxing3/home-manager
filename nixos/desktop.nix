{
  lib,
  pkgs,
  config,
  userSettings,
  ...
}: let
  oxwmPkgs = import ../modules/shared/oxwm {inherit pkgs;};
  inherit (oxwmPkgs) oxwm-session oxwm-autostart;
  screenshot-to-clipboard = pkgs.writeShellApplication {
    name = "screenshot-to-clipboard";
    runtimeInputs = with pkgs; [coreutils maim xclip];
    text = ''
      maim --select | xclip -selection clipboard -target image/png -in
    '';
  };
  gruvbox = ../themes/gruvbox-dark-medium;
  wallpaper = pkgs.fetchurl {
    url = lib.removeSuffix "\n" (builtins.readFile (gruvbox + "/backgroundurl.txt"));
    sha256 = lib.removeSuffix "\n" (builtins.readFile (gruvbox + "/backgroundsha256.txt"));
  };
in {
  imports = [./greetd.nix];

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
  # keyd's virtual pointer is a mouse, not a touchpad; twofinger fails and
  # can leave the core pointer without a working slave.
  services.libinput.mouse.scrollMethod = "button";

  services.xserver.enable = true;
  # Manual startx after getty autologin (no display manager race).
  services.xserver.autorun = false;
  services.xserver.displayManager.startx.enable = true;
  services.xserver.displayManager.lightdm.enable = false;
  # Ctrl+Alt+Fn leaving vt1 pauses X via logind; pointer/keyboard then float
  # and oxwm looks frozen (mouse "not working" on a still-visible framebuffer).
  services.xserver.serverFlagsSection = ''
    Option "DontVTSwitch" "on"
  '';
  # evdev catchalls fight libinput (add then immediately "device removed").
  environment.etc."X11/xorg.conf.d/10-evdev.conf".text = lib.mkForce ''
    # Disabled: xf86-input-libinput owns all XI devices.
  '';

  # Autologin tty1 when greetd is off. Do not define systemd.services."getty@tty1"
  # (nixpkgs#429775, 203/EXEC). greetd.nix takes tty1 and the session list.
  services.getty.autologinUser = lib.mkIf (!config.services.greetd.enable) userSettings.username;

  # NixOS /etc/profile does not source /etc/profile.d; hook login shells.
  # Match this login's VT/tty only — never /sys/class/tty/tty0/active
  # (that is the HDMI foreground, so a tty2 login would steal startx).
  environment.loginShellInit = lib.mkIf (!config.services.greetd.enable) ''
    if [ -z "''${DISPLAY:-}" ]; then
      case "''${XDG_VTNR:-}:$(tty 2>/dev/null || true)" in
        1:*|*:/dev/tty1) exec startx ;;
      esac
    fi
  '';

  environment.etc."X11/xinit/xinitrc".text = ''
    #!/bin/sh
    exec ${lib.getExe oxwm-session}
  '';

  environment.etc."oxwm/config.lua".source = oxwmPkgs.configLua;
  # sessionVariables is consumed by pam_env, which rejects `$VAR` expansion.
  environment.variables.TERMINFO_DIRS = "${pkgs.ncurses}/share/terminfo";
  environment.sessionVariables.XDG_SESSION_TYPE = "x11";

  # Sogou Pinyin is not in nixpkgs. Use fcitx5 + Rime for oxwm.
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-rime
      fcitx5-gtk
      qt6Packages.fcitx5-configtool
    ];
  };

  # Setuid FUSE helpers for rclone/user mounts (Nix store binaries cannot be setuid).
  programs.fuse.enable = true;
  programs.fuse.userAllowOther = true;

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
    pavucontrol
    at-spi2-core
    ncurses
    screenshot-to-clipboard
    oxwm-autostart
    oxwm-session
  ];
}
