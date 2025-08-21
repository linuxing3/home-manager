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
    nix-doom-emacs-unstraightened =  {
      url = "github:marienz/nix-doom-emacs-unstraightened";
      inputs.nixpkgs.follows = "";
    };
    agenix.url = "github:ryantm/agenix";
  };

  outputs =
    inputs @ {
      self,
      nixpkgs,
      home-manager,
      stylix,
      agenix,
      nix-doom-emacs-unstraightened,
      ...
    }:
    let
      # ---- SYSTEM SETTINGS ---- #
      systemSettings = {
        system = "x86_64-linux"; # system arch
        hostname = "nixos"; # hostname
        profile = "work"; # select a profile defined from my profiles directory
        timezone = "America/Sao_Paulo"; # select timezone
        locale = "en_US.UTF-8"; # select locale
        bootMode = "uefi"; # uefi or bios
        bootMountPath = "/boot"; # mount path for efi boot partition; only used for uefi boot mode
        grubDevice = ""; # device identifier for grub; only used for legacy (bios) boot mode
        gpuType = "intel"; # amd, intel or nvidia; only makes some slight mods for amd at the moment
      };
      # ----- USER SETTINGS ----- #
      userSettings = rec {
        username = "efwmc"; # username
        name = "efwmc"; # name/identifier
        email = "linuxing3@qq.com"; # email (used for certain configurations)
        dotfilesDir = "/home/efwmc/.dotfiles"; # absolute path of the local repo
        initialHashedPassword = "$7$CU..../....qejXlflvte/eOFsclGcRG0$vPxrUfc8MZh/9VY1py86B8GVs516vrQcScjvN/YEs5B";
        mainSshAuthorizedKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOm5HPR9bV+g/kWwDLzBCgCIija6GnHseUEthM+vX40l linuxing3@qq.com"
        ];
        theme = "emil"; # selcted theme from my themes directory (./themes/)
        wm = "hyprland"; # Selected window manager or desktop environment; must select one in both ./user/wm/ and ./system/wm/
        # window manager type (hyprland or x11) translator
        wmType =
          if ((wm == "hyprland") || (wm == "plasma"))
          then "wayland"
          else "x11";
        browser = "qutebrowser"; # Default browser; must select one from ./user/app/browser/
        spawnBrowser =
          if ((browser == "qutebrowser") && (wm == "hyprland"))
          then "qutebrowser-hyprprofile"
          else
            (
              if (browser == "qutebrowser")
              then "qutebrowser --qt-flag enable-gpu-rasterization --qt-flag enable-native-gpu-memory-buffers --qt-flag num-raster-threads=4"
              else browser
            ); # Browser spawn command must be specail for qb, since it doesn't gpu accelerate by default (why?)
        defaultRoamDir = "Personal.p"; # Default org roam directory relative to ~/Org
        term = "kitty"; # Default terminal command;
        font = "Intel One Mono"; # Selected font
        fontPkg = pkgs.intel-one-mono; # Font package
        editor = "emacsclient"; # Default editor;
        # editor spawning translator
        # generates a command that can be used to spawn editor inside a gui
        # EDITOR and TERM session variables must be set in home.nix or other module
        # I set the session variable SPAWNEDITOR to this in my home.nix for convenience
        spawnEditor =
          if (editor == "emacsclient")
          then "emacsclient -c -a 'emacs'"
          else
            (
              if ((editor == "vim") || (editor == "nvim") || (editor == "nano"))
              then "exec " + term + " -e " + editor
              else
                (
                  if (editor == "neovide")
                  then "neovide -- --listen /tmp/nvimsocket"
                  else "hx"
                )
            );
      };
      pkgs = import nixpkgs {
        system = systemSettings.system;
        config = {
          allowUnfree = true;
          allowUnfreePredicate = _: true;
        };
        overlays = [
          (finale: prev: {
            nnn = prev.nnn.override (oldAttrs: {
              withNerdIcons = true;
            });
          })
        ];
      };
      supportedSystems = [
        "x86_64-linux"
      ];
      forAllSystems = inputs.nixpkgs.lib.genAttrs supportedSystems;
      nixpkgsFor = forAllSystems (system: import inputs.nixpkgs {inherit system;});
    in
    {
      homeConfigurations."efwmc" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          stylix.homeModules.stylix
          nix-doom-emacs-unstraightened.homeModule
          agenix.homeManagerModules.default
          ({config, ...}: {
            age.secrets = {
              api.file = ./security/api-keys.age;
            };
          })
          (./. + "/profiles" + ("/" + systemSettings.profile) + "/home.nix")
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
            (./. + "/profiles" + ("/" + systemSettings.profile) + "/configuration.nix")
            # security
            agenix.nixosModules.default
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
      devShells = forAllSystems (system: {
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
              agenix.packages.${system}.default
            ];
            shellHook = ''
              # export DEEPSEEK_API_KEY=$(cat /etc/agenix/deepseek-token)
            '';
          };
      });
    };
}

