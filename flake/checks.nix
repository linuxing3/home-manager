{inputs, ...}: {
  perSystem = {pkgs, ...}: let
    src = inputs.self;
    qualityPaths = [
      "flake/devshells.nix"
      "flake/packages.nix"
      "flake/checks.nix"
      "profiles/work/home.nix"
      "profiles/work/packages.nix"
      "modules/tui/nnn-plugins.nix"
      "modules/app/ai-agents"
      "overlays/packages/dsh.nix"
      "modules/app/virtualization/default.nix"
      "modules/app/hx-anywhere/default.nix"
    ];
    qualityPathArgs = builtins.concatStringsSep " " qualityPaths;
  in {
    checks = {
      formatting =
        pkgs.runCommand "home-manager-flake-formatting-check" {
          nativeBuildInputs = [pkgs.alejandra];
        } ''
          cd ${src}
          alejandra --check ${qualityPathArgs}
          touch $out
        '';

      lint =
        pkgs.runCommand "home-manager-flake-lint-check" {
          nativeBuildInputs = [
            pkgs.deadnix
            pkgs.statix
          ];
        } ''
          cd ${src}
          statix check flake
          deadnix --no-lambda-pattern-names ${qualityPathArgs}
          touch $out
        '';

      syntax =
        pkgs.runCommand "home-manager-flake-syntax-check" {
          nativeBuildInputs = [pkgs.nix];
        } ''
          cd ${src}
          find flake -name '*.nix' -print0 | xargs -0 -n1 sh -c 'nix-instantiate --parse "$1" >/dev/null' _
          nix-instantiate --parse flake.nix >/dev/null
          touch $out
        '';
    };
  };
}
