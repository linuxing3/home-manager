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
  services.xserver.enable = true;
  services.xserver.autorun = false;
  services.xserver.displayManager.startx.enable = true;
  services.xserver.displayManager.startx.generateScript = true;
  services.xserver.displayManager.lightdm.enable = false;

  # TTY1: log in as Designers with no password prompt, then start oxwm.
  services.getty.autologinUser = userSettings.username;
  environment.loginShellInit = ''
    if [ -z "$DISPLAY" ] && [ "$(tty)" = /dev/tty1 ]; then
      exec startx
    fi
  '';
  services.xserver.windowManager.session = [
    {
      name = "oxwm";
      start = ''
        ${lib.getExe pkgs.oxwm} &
        waitPID=$!
      '';
    }
  ];
  services.xserver.displayManager.startx.extraCommands = ''
    mkdir -p "$HOME/.config/oxwm"
    ln -sfn /etc/oxwm/config.lua "$HOME/.config/oxwm/config.lua"
    ${pkgs.xrdb}/bin/xrdb -merge "$HOME/.Xresources" || true
  '';

  environment.etc."oxwm/config.lua".source = ../modules/wm/oxwm/config.lua;

  environment.systemPackages = with pkgs; [
    oxwm
    dmenu
    st
    maim
    xclip
    xinit
    xrdb
    xsetroot
    feh
    brave
    screenshot-to-clipboard
  ];
}
