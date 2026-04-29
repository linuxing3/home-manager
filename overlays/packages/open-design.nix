{ inputs }:
final: prev:
{
  open-design = final.callPackage ../../modules/pkgs/open-design.nix { };
}
