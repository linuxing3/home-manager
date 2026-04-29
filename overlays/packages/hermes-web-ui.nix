{ inputs }:
final: prev:
{
  hermes-web-ui = final.callPackage ../../modules/pkgs/hermes-web-ui.nix { };
}
