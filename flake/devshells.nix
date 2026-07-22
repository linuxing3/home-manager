{inputs, ...}: {
  imports = [./checks.nix];

  perSystem = {
    system,
    pkgs,
    ...
  }: {
    devShells.default = pkgs.mkShell {
      packages = with pkgs; [
        deadnix
        statix
        nixd
        nil
        alejandra
        nixpkgs-fmt
        nixpkgs-lint
        inputs.agenix.packages.${system}.default
      ];
    };
  };
}
