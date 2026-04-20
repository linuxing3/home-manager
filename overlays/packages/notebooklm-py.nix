{ inputs }:
final: prev:
{
  notebooklm-py = final.callPackage ../../modules/pkgs/notebooklm-py.nix { };
}
