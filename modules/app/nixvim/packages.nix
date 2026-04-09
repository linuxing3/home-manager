{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.home.nixvim;
  # --- Editor/runtime toolchain packages -----------------------------------
  nixvimPackages = with pkgs; [
    # formatters
    python3Packages.black
    python3Packages.isort
    python3Packages.uv
    nodePackages.prettier
    shfmt
    go # provides gofmt and goimports
    rustfmt
    # # linters
    alejandra
    deadnix
    nixpkgs-fmt
    python3Packages.pylint
    stylua
    statix
    yamlfmt
    # tools
    lsof
    # pkgs.opencode
    # pkgs.opencode-desktop
    # tree-sitter
  ];
in {
  config = lib.mkIf cfg.enable {
    home.packages = nixvimPackages;
  };
}
