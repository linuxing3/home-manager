{inputs, ...}: {
  imports = [./checks.nix];

  perSystem = {
    system,
    pkgs,
    ...
  }: let
    llm-agents = inputs.llm-agents.packages.${system};
  in {
    # Canonical project env for `.envrc` (`use flake`) and `nix develop`.
    # Desktop packages stay in Home Manager; this shell adds repo tools only.
    devShells.default = pkgs.mkShell {
      packages = with pkgs; [
        deadnix
        statix
        nixd
        nil
        alejandra
        nixpkgs-fmt
        nixpkgs-lint
        cursor-cli
        pi-coding-agent
        xclip
        inputs.agenix.packages.${system}.default
        llm-agents.herdr
      ];
    };
  };
}
