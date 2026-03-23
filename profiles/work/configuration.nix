{ pkgs, userSettings, systemSettings, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      # ./stylix.nix
      # ../../modules/hardware/graphics.nix
    ];

  fonts.packages = with pkgs; [
    # dejavu_fonts
    # intel-one-mono
    # julia-mono
    # material-design-icons
    # font-awesome
    # noto-fonts-emoji
    # source-sans
    # source-serif
    # source-han-sans
    # source-han-serif
    # nerd-fonts.jetbrains-mono
    # nerd-fonts.symbols-only # symbols icon only
    # nerd-fonts.fira-code
    # nerd-fonts.iosevka
  ];

  fonts.fontDir.enable = true;

  services.libinput.mouse.leftHanded = true;
  services.libinput.mouse.naturalScrolling = false;

  # console
  # fonts and inputs
  console = {
    font = "${pkgs.terminus_font}/share/consolefonts/ter-u28n.psf.gz";
    keyMap = "us";
  };
  services.getty.autologinUser = userSettings.username;

  # xserver
  # programs = {
    # hyprland = {
    #   enable = true;
    #   # withUWSM = true;
    #   xwayland = {
    #     enable = true;
    #   };
    #   portalPackage = pkgs.xdg-desktop-portal-hyprland;
    # };
    # niri = {
    #   enable = true;
    # };
  # };

  # services.xserver = {
  #   enable = true;
  #   windowManager.xmonad = {
  #     enable = true;
  #     enableConfiguredRecompile = true;
  #     enableContribAndExtras = true;
  #   };
  #   windowManager.dwm = {
  #     enable = true;
  #   };
  # };

  # # Enable CUPS to print documents.
  # services.printing.enable = true;

  # # Enable sound with pipewire.
  # services.pulseaudio.enable = false;
  # security.rtkit.enable = true;
  # services.pipewire = {
  #   enable = true;
  #   alsa.enable = true;
  #   alsa.support32Bit = true;
  #   pulse.enable = true;
  # };

  # Enable gv fifileSystems
  # services.gvfs.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "*";
  };

  # Enable auto mounts
  # services.autofs = {
  #   enable = true;
  #   autoMaster = let
  #     mapConf = pkgs.writeText "autofs.mnt" ''
  #       win7 -fstype=ntfs :/dev/disk/by-uuid/523481103480F7ED
  #       app -fstype=ntfs :/dev/disk/by-uuid/9ED80960D8093853
  #       data -fstype=ntfs :/dev/disk/by-uuid/8A7CFD4C7CFD3393
  #     '';
  #   in ''
  #     /autofs ${mapConf} --timeout 20
  #   '';
  # };

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

  i18n.inputMethod = {
    enable = true;
    type = "ibus";
    ibus.engines = with pkgs.ibus-engines; [
      libpinyin
      pinyin
    ];
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
    uid = 1001;
    initialHashedPassword = userSettings.initialHashedPassword;
    openssh.authorizedKeys.keys = userSettings.mainSshAuthorizedKeys;
  };

  # Install firefox.
  # programs.firefox.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # neovim
    # vim
    helix-steel-system

    wget
    curl
    git
    gh
    lazygit

    zellij
    tmux

    nnn
    yazi
    lf

    # st
    # dwm
 
    dosfstools
    exfat
    nfs-utils
    btrfs-progs
    btrfs-snap
    # for hp printer
    hplip

    cachix
    gnupg

    # wayland runtime/system libs
    wayland
    wayland-protocols
    libxkbcommon
    libglvnd
    mesa
    swiftshader
    xwayland
    xdg-desktop-portal
    xdg-desktop-portal-gtk

    # (
    #   let
    #     base = pkgs.appimageTools.defaultFhsEnvArgs;
    #   in
    #     pkgs.buildFHSEnv (base
    #       // {
    #         name = "fhs";
    #         targetPkgs = pkgs: (base.targetPkgs pkgs) ++ [pkgs.pkg-config];
    #         profile = "export FHS=1";
    #         runScript = "bash";
    #         extraOutputsToInstall = ["dev"];
    #       })
    # )
  ];

  # programs.nix-ld = {
  #   enable = true;
  #   libraries = with pkgs; [
  #     stdenv.cc.cc
  #   ];
  # };

  # programs.gnupg.agent = {
  #    enable = true;
  #    enableSSHSupport = true;
  # };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  nix.settings.substituters = [
    "https://nix-community.cachix.org"
    "https://ghostty.cachix.org"
    "https://cache.nixos.org"
  ];

  nix.settings.trusted-substituters = [
    "https://nix-community.cachix.org"
    "https://ghostty.cachix.org"
    "https://cache.nixos.org"
  ];

  nix.settings.trusted-public-keys = [
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "ghostty.cachix.org-1:QB389yTa6gTyneehvqG58y0WnHjQOqgnA+wBnpWWxns="
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
  ];

  networking.interfaces.enp11s0.ipv4.addresses = [
    {
      address = "10.10.30.11";
      prefixLength = 24;
    }
  ];
  networking.defaultGateway = "10.10.30.1";
  networking.nameservers = [
    "8.8.8.8"
    "8.8.4.4"
    "1.1.1.1"
  ];

  # nix.settings.extra-substituters = [
  #   "https://yazi.cachix.org"
  #   "https://helix.cachix.org"
  # ];
  # nix.settings.extra-trusted-public-keys = [
  #   "yazi.cachix.org-1:Dcdz63NZKfvUCbDGngQDAZq6kOroIrFoyO064uvLh8k="
  #   "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs="
  # ];

  nix.settings.trusted-users = [
    "root"
    "@wheel"
    userSettings.username
  ];

  system.stateVersion = "24.11"; # Did you read the comment?

}
