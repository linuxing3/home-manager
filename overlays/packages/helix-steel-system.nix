{ inputs }:
final: prev:
{
  helix-steel-system = final.helix.overrideAttrs (old: {
    cargoBuildFeatures =
      (old.cargoBuildFeatures or [ ])
      ++ [
        "git"
        "steel"
      ];
  });
}
