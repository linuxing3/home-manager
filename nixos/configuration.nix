{
  pkgs,
  userSettings,
  systemSettings,
  ...
}: {
  networking.hostName = "nixos";
  networking.firewall.enable = true;
  # Deepin 6.6.y has ipt_rpfilter (IPv4) but CONFIG_IP6_NF_MATCH_RPFILTER
  # is unset. NixOS still appends ip6tables rpfilter and firewall.service
  # exits 4 ("Extension rpfilter revision 0 not supported").
  networking.firewall.checkReversePath = false;

  time.timeZone = systemSettings.timezone;
  i18n.defaultLocale = systemSettings.locale;
  i18n.supportedLocales = [
    "C.UTF-8/UTF-8"
    "en_US.UTF-8/UTF-8"
    "zh_CN.UTF-8/UTF-8"
  ];
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

  # Kernel default at 1920x1080 is 8x16. Spleen 32x64 is 4x the pixel area of Terminus ter-v32n (16x32).
  console.earlySetup = true;
  console.packages = [pkgs.spleen];
  console.font = "spleen-32x64.psfu";

  nixpkgs.hostPlatform = systemSettings.system;
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = ["nix-command" "flakes"];
  boot.supportedFilesystems = ["btrfs" "ext4" "vfat"];

  # Removable EFI on sda1 so UOS NVRAM on nvme0n1 stays the firmware default.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "nodev";
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.grub.useOSProber = true;
  boot.loader.grub.gfxmodeEfi = "1920x1080,auto";
  # keep freezes the Stylix GRUB frame: Glenfly has no initrd KMS, so the
  # kernel/KeyVault prompt never appears on HDMI. Hand off in text mode.
  boot.loader.grub.gfxpayloadEfi = "text";
  boot.loader.efi.canTouchEfiVariables = false;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  # Last console= is /dev/console (systemd-ask-password). tty0 is HDMI;
  # ttyAMA0 is the Phytium UART, matching UOS `console=tty`.
  boot.consoleLogLevel = 7;
  boot.initrd.verbose = true;
  boot.kernelParams = [
    "console=ttyAMA0,115200n8"
    "console=tty0"
  ];

  users.mutableUsers = true;
  users.users.${userSettings.username} = {
    isNormalUser = true;
    extraGroups = ["wheel" "networkmanager" "audio" "video" "input" "keyd"];
    hashedPassword = userSettings.initialHashedPassword;
    openssh.authorizedKeys.keys =
      userSettings.mainSshAuthorizedKeys
      ++ [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFjKk9OcBNVc24J+zly4Z3IJ2eEZbQVN1LsBBesOE+Xl Designers@Designers-PC"
      ];
  };
  # Initrd emergency /etc/shadow is root:* unless this is set. sulogin then
  # prints "Cannot open access to console, the root account is locked" and
  # the machine is stuck (generation 22). Same hash as Designers.
  users.users.root.hashedPassword = userSettings.initialHashedPassword;
  users.users.root.openssh.authorizedKeys.keys =
    userSettings.mainSshAuthorizedKeys;
  boot.initrd.systemd.emergencyAccess = userSettings.initialHashedPassword;
  # After switch-root, emergency/rescue still read the real shadow. Root was
  # created locked (mutableUsers); force sulogin so a failed .mount is usable.
  systemd.services.emergency.environment.SYSTEMD_SULOGIN_FORCE = "1";
  systemd.services.rescue.environment.SYSTEMD_SULOGIN_FORCE = "1";

  security.sudo.extraRules = [
    {
      users = [userSettings.username];
      commands = [
        {
          command = "ALL";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
  };

  environment.systemPackages = with pkgs; [
    git
    vim
    helix
    tmux
    nnn
    ripgrep
    fzf
    elinks
    btrfs-progs
    efibootmgr
    os-prober
  ];

  system.stateVersion = "25.11";
}
