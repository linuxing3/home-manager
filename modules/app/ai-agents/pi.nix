{
  config,
  lib,
  pkgs,
  ...
}: let
  ai = import ./lib.nix {inherit config lib pkgs;};
  piCompatWrapper = pkgs.writeShellApplication {
    name = "pi";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.fd
      pkgs.ripgrep
    ];
    text = ''
      profile_pi=${lib.escapeShellArg "${ai.profileBin}/pi"}
      system_loader=/lib/ld-linux-aarch64.so.1

      if [[ ! -x "$profile_pi" ]]; then
        echo "pi: the Nix profile executable is missing: $profile_pi" >&2
        exit 127
      fi

      resolved_pi=$(readlink -f -- "$profile_pi")
      package_root=$(dirname -- "$(dirname -- "$resolved_pi")")
      package_dir="$package_root/libexec/pi"
      standalone_pi="$package_dir/pi"

      # llm-agents.nix's Bun standalone mixes the Nix loader with UOS libc on
      # aarch64. Starting it with the UOS loader keeps the runtime consistent.
      if [[ -x "$system_loader" && -x "$standalone_pi" ]]; then
        export PI_PACKAGE_DIR="$package_dir"
        export PI_SKIP_VERSION_CHECK=1
        export PI_TELEMETRY=0
        exec "$system_loader" "$standalone_pi" "$@"
      fi

      exec "$profile_pi" "$@"
    '';
  };
  piDefaults = pkgs.writeText "pi-defaults.json" (builtins.toJSON {
    theme = "dark";
    defaultProvider = "openai-codex";
    defaultModel = "gpt-5.6-terra";
  });
in {
  home = {
    packages = [pkgs.pi-switch];
    file.".local/bin/pi".source = "${piCompatWrapper}/bin/pi";
    file.".local/bin/pi-switch".source = "${pkgs.pi-switch}/bin/pi-switch";
    activation.mergePiSettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
      ${ai.activationPreamble}
      ${ai.mergeJsonFile "${ai.homeDir}/.pi/agent/settings.json" piDefaults}
      pi_settings=${lib.escapeShellArg "${ai.homeDir}/.pi/agent/settings.json"}
      ${pkgs.jq}/bin/jq '
        .packages //= []
        | if any(.packages[]?; . == "npm:@heihei0299/pi-switch") then .
          else .packages += ["npm:@heihei0299/pi-switch"]
          end
      ' "$pi_settings" >"$pi_settings.hm-new"
      ${pkgs.coreutils}/bin/chmod --reference="$pi_settings" "$pi_settings.hm-new"
      ${pkgs.coreutils}/bin/mv "$pi_settings.hm-new" "$pi_settings"
    '';
    activation.installPiSwitch = lib.hm.dag.entryAfter ["installPackages" "linkGeneration"] ''
      pi_bin=${lib.escapeShellArg "${ai.homeDir}/.local/bin/pi"}
      if [[ -x "$pi_bin" ]]; then
        if [[ ! -d ${lib.escapeShellArg "${ai.homeDir}/.pi/agent/npm/node_modules/@heihei0299/pi-switch"} ]]; then
          "$pi_bin" install npm:@heihei0299/pi-switch
        fi
      else
        echo "pi activation: skipping pi-switch install; missing $pi_bin" >&2
      fi
    '';
  };
}
