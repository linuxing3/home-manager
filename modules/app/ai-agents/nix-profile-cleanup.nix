{
  config,
  lib,
  pkgs,
  ...
}: let
  ai = import ./lib.nix {inherit config lib pkgs;};
  names = [
    "herdr"
    "pi"
    "omp"
    "collie"
    "orca"
    "cursor-agent"
  ];
in {
  imports = [
    {
      # The pinned Home Manager still uses the deprecated Nix command alias.
      options.home.activation = lib.mkOption {
        apply = activation: let
          installPackages = activation.installPackages;
        in
          assert lib.assertMsg (
            config.submoduleSupport.externalPackageInstall
            || lib.hasInfix "run $oldNix profile install $1" installPackages.data
          ) "Home Manager installPackages changed; review the profile add compatibility override.";
            activation
            // {
              installPackages =
                installPackages
                // {
                  data = builtins.replaceStrings ["profile install"] ["profile add"] installPackages.data;
                };
            };
      };
    }
  ];

  # These binaries are Home Manager packages. A leftover
  # `nix profile add github:numtide/llm-agents.nix#…` collides with
  # `home-manager-path` on the same ~/.nix-profile.
  home.activation.removeNixProfileLlmAgents = lib.hm.dag.entryBefore ["installPackages"] ''
    ${ai.activationPreamble}
    nix_bin=${lib.escapeShellArg "${pkgs.nix}/bin/nix"}
    if [[ -x "$nix_bin" ]]; then
      profile_json=$("$nix_bin" --extra-experimental-features "nix-command flakes" profile list --json)
      matches=$(printf '%s' "$profile_json" | ${pkgs.jq}/bin/jq -r \
        --argjson managed ${lib.escapeShellArg (builtins.toJSON names)} \
        '.elements | keys[] as $name | select($managed | index($name)) | $name')
      if [[ -n "$matches" ]]; then
        while IFS= read -r name; do
          run "$nix_bin" --extra-experimental-features "nix-command flakes" \
            profile remove "$name"
        done <<< "$matches"
      fi
    fi
  '';
}
