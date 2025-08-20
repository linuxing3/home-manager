{ config, pkgs, userSettings, systemSettings, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable networking
  networking.hostName = "nixos"; # Define your hostname.
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Sao_Paulo";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "pt_BR.UTF-8";
    LC_IDENTIFICATION = "pt_BR.UTF-8";
    LC_MEASUREMENT = "pt_BR.UTF-8";
    LC_MONETARY = "pt_BR.UTF-8";
    LC_NAME = "pt_BR.UTF-8";
    LC_NUMERIC = "pt_BR.UTF-8";
    LC_PAPER = "pt_BR.UTF-8";
    LC_TELEPHONE = "pt_BR.UTF-8";
    LC_TIME = "pt_BR.UTF-8";
  };


  fonts.packages = with pkgs; [
    dejavu_fonts
    intel-one-mono
    nerd-fonts.jetbrains-mono
  ];

  fonts.fontDir.enable = true;

  # console
  console.font = "LatArCyrHeb-16";
  services.getty.autologinUser = "efwmc";

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

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.efwmc = {
    isNormalUser = true;
    description = "efwmc";
    extraGroups = [ "networkmanager" "wheel" "users" "video" ];
    packages = with pkgs; [
    #  thunderbird
    ];
    initialHashedPassword = userSettings.initialHashedPassword;
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
    zellij
    nnn
    gnupg
  ];

  programs.gnupg.agent = {
     enable = true;
     enableSSHSupport = true;
  };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  system.stateVersion = "24.11"; # Did you read the comment?

}
