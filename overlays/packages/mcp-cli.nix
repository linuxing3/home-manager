{ inputs }:
final: prev:
{
  mcp-cli = final.callPackage ../../modules/pkgs/mcp-cli.nix { };
}
