{ inputs }:
final: prev:
{
  lancedb-mcp = final.callPackage ../../modules/pkgs/lancedb-mcp.nix { };
}
