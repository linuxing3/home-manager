{
  description = ''
    NixOS beside UOS on /dev/sda (WDC WD10EARZ).

    Root is sda4 btrfs @nixos, with @nix, @home, and @swap (16G swapfile). EFI is sda1, /boot is sda2,
    /share is sda3 watermelon. UOS stays on nvme0n1.

    Never run `disko --mode destroy,format` or `disko-install` against this disk.
    Create subvolumes and mount, then `nixos-install --flake .#sda --root /mnt`.
  '';

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    disko.url = "github:nix-community/disko/latest";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Deepin vendor tree (Phytium HDA + Glenfly Arise). Prefer 6.6.y over
    # EOL/UOS-K5.10-LTS — same drivers, newer ABI for NixOS userspace.
    deepin-kernel = {
      url = "github:deepin-community/kernel/linux-6.6.y";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    disko,
    stylix,
    deepin-kernel,
  }: let
    systemSettings = import ../nix/system-settings.nix;
    userSettings = import ../nix/user-settings.nix {
      inherit nixpkgs systemSettings;
    };
    system = systemSettings.system;
    pkgs = nixpkgs.legacyPackages.${system};
    sdaDisko = import ./disko-config.nix {
      device = "/dev/sda";
    };
  in {
    diskoConfigurations.sda = sdaDisko;

    nixosModules.sda-disk = {
      imports = [disko.nixosModules.disko];
      disko = sdaDisko.disko // {enableConfig = false;};
    };

    nixosModules.sda = {
      imports = [
        stylix.nixosModules.stylix
        disko.nixosModules.disko
        ./configuration.nix
        ./hardware-sda.nix
        ./hardware-host.nix
        ./desktop.nix
        ./stylix-theme.nix
        ./keyd.nix
        ./home-snapshot.nix
        ./keyvault-boot.nix
        ./udev.nix
      ];
      disabledModules = ["services/hardware/udev.nix"];
      # Layout is documentary. Live sda has no Disko PARTLABELs; mounts come
      # from hardware-sda.nix UUIDs. Never set enableConfig true on this disk.
      disko = sdaDisko.disko // {enableConfig = false;};
    };

    # Opt-in: Deepin 6.6.y with snd-hda-phytium + arise DRM.
    nixosModules.phytium-kernel = {
      imports = [./phytium-kernel.nix];
    };

    packages.${system} = {
      default = disko.packages.${system}.default;
      disko = disko.packages.${system}.default;
      # Build just the vendor kernel (slow, large IFD) to smoke-test packaging:
      #   nix build './disko#linux-phytium' -L
      linux-phytium =
        (import ./kernel-phytium.nix {
          inherit (pkgs) lib;
          inherit pkgs;
          src = deepin-kernel;
        }).kernel;
    };

    # Default beside-UOS profile: mainline nixpkgs kernel (modesetting + HDMI).
    nixosConfigurations.sda = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit userSettings systemSettings;
      };
      modules = [self.nixosModules.sda];
    };

    # Same disk layout, Deepin vendor kernel for analog audio + Arise DRM.
    #   nix build './disko#nixosConfigurations.sda-phytium.config.system.build.toplevel' -L
    nixosConfigurations.sda-phytium = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit userSettings systemSettings deepin-kernel;
      };
      modules = [
        self.nixosModules.sda
        self.nixosModules.phytium-kernel
      ];
    };
  };
}
