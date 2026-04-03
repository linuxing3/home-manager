{ inputs, ... }:
{
  perSystem =
    { system, pkgs, ... }:
    {
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
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
