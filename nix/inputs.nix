{
  nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  home-manager = {
    url = "github:nix-community/home-manager";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  flake-parts.url = "github:hercules-ci/flake-parts";
  flake-utils.url = "github:numtide/flake-utils";
  nix-index-database = {
    url = "github:nix-community/nix-index-database";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  stylix = {
    url = "github:nix-community/stylix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  agenix.url = "github:ryantm/agenix";
  doxx.url = "github:bgreenwell/doxx";
  xleak.url = "github:bgreenwell/xleak";
}
