{inputs, ...}: {
  perSystem = {pkgs, ...}: let
    src = inputs.self;
    qualityPaths = [
      "flake/devshells.nix"
      "flake/packages.nix"
      "flake/checks.nix"
      "flake/nixos.nix"
      "nixos"
      "modules/shared/oxwm"
      "modules/wm/xmonad"
      "modules/wm/dwm"
      "overlays/packages/dwm.nix"
      "profiles/work/home.nix"
      "profiles/work/packages.nix"
      "modules/tui/nnn-plugins.nix"
      "modules/app/ai-agents"
      "overlays/packages/dsh.nix"
      "overlays/packages/agent-browser.nix"
      "overlays/packages/lightpanda.nix"
      "modules/app/virtualization/default.nix"
      "modules/app/credential-backup/default.nix"
      "modules/app/crabbox/default.nix"
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
          export NIX_STATE_DIR="$TMPDIR/nix"
          mkdir -p "$NIX_STATE_DIR"
          cd ${src}
          find flake -name '*.nix' -print0 | xargs -0 -n1 sh -c 'nix-instantiate --parse "$1" >/dev/null' _
          find nixos -name '*.nix' -print0 | xargs -0 -n1 sh -c 'nix-instantiate --parse "$1" >/dev/null' _
          nix-instantiate --parse flake.nix >/dev/null
          touch $out
        '';
    };
  };
}
