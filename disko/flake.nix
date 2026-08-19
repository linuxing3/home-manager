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
  };

  outputs = {
    self,
    nixpkgs,
    disko,
    stylix,
  }: let
    systemSettings = import ../nix/system-settings.nix;
    userSettings = import ../nix/user-settings.nix {
      inherit nixpkgs systemSettings;
    };
    system = systemSettings.system;
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

    packages.${system} = {
      default = disko.packages.${system}.default;
      disko = disko.packages.${system}.default;
    };

    nixosConfigurations.sda = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit userSettings systemSettings;
      };
      modules = [self.nixosModules.sda];
    };
  };
}
