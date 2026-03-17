{ inputs, ... }:
{
  perSystem =
    { system, ... }:
    let
      pkgs = import inputs.nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          allowUnsupportedSystem = true;
          allowUnfreePredicate = _: true;
        };
        overlays = [ (import ../overlays) ];
      };
    in
    {
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          nixd
          nil
          alejandra
          helix
          git
          gh
          just
          inputs.agenix.packages.${system}.default
        ];
      };
    };
}
