{
  config,
  lib,
  pkgs,
  ...
}: let
  ai = import ./lib.nix {inherit config lib pkgs;};
  names = lib.concatStringsSep " " [
    "herdr"
    "pi"
    "collie"
    "cursor-agent"
  ];
in {
  # These four binaries are Home Manager packages. A leftover
  # `nix profile add github:numtide/llm-agents.nix#…` collides with
  # `home-manager-path` on the same ~/.nix-profile.
  home.activation.removeNixProfileLlmAgents = lib.hm.dag.entryBefore ["installPackages"] ''
    ${ai.activationPreamble}
    nix_bin=${lib.escapeShellArg "${pkgs.nix}/bin/nix"}
    if [[ -x "$nix_bin" ]]; then
      for name in ${names}; do
        run "$nix_bin" --extra-experimental-features "nix-command flakes" \
          profile remove "$name" || true
      done
    fi
  '';
}
