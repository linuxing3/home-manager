{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
    # home-manager.url = "github:nix-community/home-manager";
    # home-manager.inputs.nixpkgs.follows = "nixpkgs-unstable";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, ... }@input:
    let
      system = "x86_64-linux";
      overlay-unstable = final: prev: {
        unstable = nixpkgs-unstable.legacyPackages.${prev.system};
        # use this variant if unfree packages are needed:
        # unstable = import nixpkgs-unstable {
        #   inherit system;
        #   config.allowUnfree = true;
        # };

      };
    in {
      nixosConfigurations."nixos" = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          # Overlays-module makes "pkgs.unstable" available in configuration.nix
          ({ config, pkgs, ... }: { nixpkgs.overlays = [ overlay-unstable ]; })
          ./configuration.nix

	  # home-manager.nixosModules.home-manager
          # {
          #   home-manager.useGlobalPkgs = true;
          #   home-manager.useUserPackages = true;
          #   home-manager.users.vagrant = import ./home/vagrant/home.nix;
          #   home-manager.users.root = import ./home/root/home.nix;

          #   # home-manager.extraSpecialArgs = true;
          # }
        ];
      };
    };
}
