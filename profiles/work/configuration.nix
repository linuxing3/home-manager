{ config, pkgs, userSettings, systemSettings, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./stylix.nix
    ];

  fonts.packages = with pkgs; [
    dejavu_fonts
    intel-one-mono
    nerd-fonts.jetbrains-mono
  ];

  fonts.fontDir.enable = true;

  # console
  console.font = "LatArCyrHeb-16";
  services.getty.autologinUser = "efwmc";

  # xserver
  programs = {
    hyprland = {
      enable = true;
      xwayland = {
        enable = true;
      };
      portalPackage = pkgs.xdg-desktop-portal-hyprland;
    };
  };

  services.xserver = {
    enable = true;
    windowManager.xmonad = {
      enable = true;
      enableConfiguredRecompile = true;
      enableContribAndExtras = true;
    };
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Bootloader
  # Use systemd-boot if uefi, default to grub otherwise
  boot.loader.systemd-boot.enable =
    if (systemSettings.bootMode == "uefi")
    then true
    else false;
  boot.loader.efi.canTouchEfiVariables =
    if (systemSettings.bootMode == "uefi")
    then true
    else false;
  boot.loader.efi.efiSysMountPoint = systemSettings.bootMountPath; # does nothing if running bios rather than uefi
  boot.loader.grub.enable =
    if (systemSettings.bootMode == "uefi")
    then false
    else true;
  boot.loader.grub.device = systemSettings.grubDevice; # does nothing if running uefi rather than bios

  # Networking
  networking.hostName = systemSettings.hostname; # Define your hostname.
  networking.networkmanager.enable = true; # Use networkmanager

  # Timezone and locale
  time.timeZone = systemSettings.timezone; # time zone
  i18n.defaultLocale = systemSettings.locale;
  i18n.extraLocaleSettings = {
    LC_ADDRESS = systemSettings.locale;
    LC_IDENTIFICATION = systemSettings.locale;
    LC_MEASUREMENT = systemSettings.locale;
    LC_MONETARY = systemSettings.locale;
    LC_NAME = systemSettings.locale;
    LC_NUMERIC = systemSettings.locale;
    LC_PAPER = systemSettings.locale;
    LC_TELEPHONE = systemSettings.locale;
    LC_TIME = systemSettings.locale;
  };

  # User account
  users.users.${userSettings.username} = {
    isNormalUser = true;
    description = userSettings.name;
    extraGroups = [
      "networkmanager"
      "wheel"
      "input"
      "dialout"
      "video"
      "render"
    ];
    packages = [];
    uid = 1000;
    initialHashedPassword = userSettings.initialHashedPassword;
    openssh.authorizedKeys.keys = userSettings.mainSshAuthorizedKeys;
  };

  # Install firefox.
  programs.firefox.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    neovim
    vim
    helix

    wget
    curl
    git
    gh
    lazygit

    zellij
    tmux

    nnn
    yazi

    cachix
    gnupg
  ];

  programs.gnupg.agent = {
     enable = true;
     enableSSHSupport = true;
  };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  nix.settings.substituters = [
    "https://nix-community.cachix.org"
    "https://cache.nixos.org"
  ];

  nix.settings.trusted-public-keys = [
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
  ];

  nix.settings.extra-substituters = [
    "https://yazi.cachix.org"
    "https://helix.cachix.org"
  ];
  nix.settings.extra-trusted-public-keys = [
    "yazi.cachix.org-1:Dcdz63NZKfvUCbDGngQDAZq6kOroIrFoyO064uvLh8k="
    "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs="
  ];

  nix.settings.trusted-users = ["@wheel"];

  system.stateVersion = "24.11"; # Did you read the comment?

}
