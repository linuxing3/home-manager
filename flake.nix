{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs @ {
      self,
      nixpkgs,
      home-manager,
      stylix,
      ...
    }:
    let
      systemSettings = {
        system = "x86_64-linux"; # system arch
        hostname = "efwmc"; # hostname
        profile = "work"; # select a profile defined from my profiles directory
        timezone = "America/Sao_Paulo"; # select timezone
        locale = "en_US.UTF-8"; # select locale
      };
      userSettings = {
        theme = "io";
        term = "kitty"; # Default terminal command;
        font = "Intel One Mono"; # Selected font
        fontPkg = pkgs.intel-one-mono; # Font package
        editor = "emacsclient"; # Default editor;
      };
      pkgs = import nixpkgs {
        system = systemSettings.system;
        config = {
          allowUnfree = true;
          allowUnfreePredicate = _: true;
        };
      };
      supportedSystems = [
        "x86_64-linux"
      ];
      forAllSystems = inputs.nixpkgs.lib.genAttrs supportedSystems;
      nixpkgsFor = forAllSystems (system: import inputs.nixpkgs {inherit system;});
    in
    {
      homeConfigurations."efwmc" = home-manager.lib.homeManagerConfiguration {
        # pkgs = nixpkgs.legacyPackages.x86_64-linux;
        inherit pkgs;
        modules = [
          stylix.homeModules.stylix
          ./home.nix
        ];
        extraSpecialArgs = {
          inherit userSettings;
          inherit systemSettings;
          inherit inputs;
        };
      };
      nixosConfigurations = {
        system = nixpkgs.lib.nixosSystem {
          inherit pkgs;
          system = systemSettings.system;
          modules = [
            ./nixos/configuration.nix
          ]; # load configuration.nix from selected PROFILE
          specialArgs = {
            # pass config variables from above
            inherit pkgs;
            inherit systemSettings;
            inherit userSettings;
            inherit inputs;
          };
        };
      };
      devShells.default = forAllSystems (system: {
        default = let
          pkgs = nixpkgsFor.${system};
        in
          pkgs.mkShell {
            packages = with pkgs; [
              nixd
              nil
              alejandra
              helix
              git
              gh
            ];
            shellHook = ''
              export DEEPSEEK_API_KEY=$(cat /etc/agenix/deepseek-token)
            '';
          };
      });
    };
}

