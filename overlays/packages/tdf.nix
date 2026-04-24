{ inputs }:
final: prev:
{
  tdf = final.callPackage ../../modules/pkgs/tdf.nix { };
}
