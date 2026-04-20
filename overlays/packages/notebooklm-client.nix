{ inputs }:
final: prev:
{
  notebooklm-client = final.callPackage ../../modules/pkgs/notebooklm-client.nix { };
}
