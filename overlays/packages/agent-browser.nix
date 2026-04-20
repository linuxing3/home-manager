{ inputs }:
final: prev:
{
  agent-browser = final.callPackage ../../modules/pkgs/agent-browser.nix { };
}
