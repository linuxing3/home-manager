final: prev: {
  agent-browser = prev.callPackage ../../modules/pkgs/agent-browser.nix {
    inherit (final) lightpanda;
  };
}
