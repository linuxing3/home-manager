{ inputs }:
final: prev:
{
  jcode = final.callPackage ../../modules/pkgs/jcode.nix { };
}
