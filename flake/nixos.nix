{
  inputs,
  userSettings,
  systemSettings,
  ...
}: let
  inherit (inputs) self nixpkgs disko stylix deepin-kernel;
  inherit (systemSettings) system;
  nixosDir = ../nixos;
  sdaDisko = import (nixosDir + /disko-config.nix) {
    device = "/dev/sda";
  };
  sdaImports = [
    {nixpkgs.overlays = [(import ../overlays {inherit inputs;})];}
    stylix.nixosModules.stylix
    disko.nixosModules.disko
    (nixosDir + /configuration.nix)
    (nixosDir + /hardware-host.nix)
    (nixosDir + /desktop.nix)
    (nixosDir + /printing.nix)
    (nixosDir + /stylix-theme.nix)
    (nixosDir + /keyd.nix)
    (nixosDir + /home-snapshot.nix)
    (nixosDir + /keyvault-boot.nix)
    (nixosDir + /udev.nix)
  ];
in {
  flake = {
    diskoConfigurations.sda = sdaDisko;

    nixosModules = {
      sda-disk = {
        imports = [disko.nixosModules.disko];
        disko = sdaDisko.disko // {enableConfig = false;};
      };

      sda = {
        imports =
          sdaImports
          ++ [
            (nixosDir + /hardware-sda.nix)
          ];
        disabledModules = ["services/hardware/udev.nix"];
        # Layout is documentary. Live sda has no Disko PARTLABELs; mounts come
        # from hardware-sda.nix UUIDs. Never set enableConfig true on this disk.
        disko = sdaDisko.disko // {enableConfig = false;};
      };

      # Same modules as sda, but / @nix @home @swap on nvme0n1p6 (nixos-nvme).
      # UOS EFI/Boot/Roota/SWAP on nvme0n1p1–p5 are untouched. /boot and /share
      # stay on sda. Never Disko-format nvme0n1.
      nvme-p6 = {
        imports =
          sdaImports
          ++ [
            (nixosDir + /hardware-nvme-p6.nix)
          ];
        disabledModules = ["services/hardware/udev.nix"];
        disko = sdaDisko.disko // {enableConfig = false;};
      };

      # Opt-in: Deepin 6.6.y with snd-hda-phytium + arise DRM.
      phytium-kernel = {
        imports = [(nixosDir + /phytium-kernel.nix)];
      };
    };

    nixosConfigurations = {
      # Default beside-UOS profile: mainline nixpkgs kernel (modesetting + HDMI).
      sda = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit userSettings systemSettings;
        };
        modules = [self.nixosModules.sda];
      };

      # Banana sda4 fallback only. Live root is nvme0n1p6 (`nvme-p6-phytium`).
      # Do not `nixos-rebuild switch` this while running from NVMe: GRUB will
      # boot sda4 whose @nix never received the new closure (generation 22).
      #   nix build '.#nixosConfigurations.sda-phytium.config.system.build.toplevel' -L
      sda-phytium = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit userSettings systemSettings deepin-kernel;
        };
        modules = [
          self.nixosModules.sda
          self.nixosModules.phytium-kernel
        ];
      };

      # NixOS on nvme0n1p6 + phytium kernel. GRUB stays removable on sda1.
      #   sudo nixos-rebuild switch --flake .#nvme-p6-phytium
      nvme-p6-phytium = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit userSettings systemSettings deepin-kernel;
        };
        modules = [
          self.nixosModules.nvme-p6
          self.nixosModules.phytium-kernel
        ];
      };
    };
  };

  perSystem = {
    system,
    pkgs,
    ...
  }: {
    packages = {
      disko = disko.packages.${system}.default;
      # Opt-in vendor kernel smoke test (large IFD). Not part of nix flake check.
      #   nix build '.#linux-phytium' -L
      linux-phytium =
        (import (nixosDir + /kernel-phytium.nix) {
          inherit (pkgs) lib;
          inherit pkgs;
          src = deepin-kernel;
        }).kernel;
    };
  };
}
