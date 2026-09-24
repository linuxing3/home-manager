{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.my.features.home;
in {
  imports = [
    inputs.nix-doom-emacs-unstraightened.homeModule
    ./gmail.nix
  ];

  options.my.features.home.doomEmacs =
    lib.mkEnableOption "Doom Emacs via nix-doom-emacs-unstraightened";

  config = lib.mkIf cfg.doomEmacs {
    programs.doom-emacs = {
      enable = true;
      doomDir = ./doomdir;
      doomLocalDir = "${config.xdg.dataHome}/nix-doom";
      experimentalFetchTree = true;
      extraPackages = epkgs: [epkgs.treesit-grammars.with-all-grammars];
      extraBinPackages = with pkgs; [
        git
        ripgrep
        fd
      ];
    };
  };
}
