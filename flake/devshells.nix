{ inputs, ... }:
{
  perSystem =
    { system, ... }:
    let
      projectOverlays = [
        (import ../overlays)
      ];
      pkgs = import inputs.nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          allowUnsupportedSystem = true;
          allowUnfreePredicate = _: true;
        };
        overlays = projectOverlays;
      };
    in
    {
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          nixd
          nil
          alejandra
          inputs.agenix.packages.${system}.default
        ];
      };
    };
}
