{inputs, ...}: {
  imports = [./checks.nix];

  perSystem = {
    system,
    pkgs,
    ...
  }: let
    llm-agents = inputs.llm-agents.packages.${system};
    agenix = inputs.agenix.packages.${system}.default;
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
        llm-agents.herdr
        llm-agents.cursor-agent
        llm-agents.pi
        xclip
        agenix
      ];
    };
  };
}
