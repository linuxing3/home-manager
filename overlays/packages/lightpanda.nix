{ inputs }:
final: prev:
{
  lightpanda = final.callPackage ../../modules/pkgs/lightpanda.nix { };
}
