_final: prev: let
  pkgs = prev.callPackage ../../modules/pkgs/homedge-proxy.nix {};
in {
  inherit (pkgs) homedge-sync homedge-clash homedge-singbox;
}
