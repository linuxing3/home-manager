{ inputs }:
final: prev:
{
  openfang = final.callPackage ../../modules/pkgs/openfang.nix { };
}
