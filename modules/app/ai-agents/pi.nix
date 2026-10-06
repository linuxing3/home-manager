{
  config,
  lib,
  pkgs,
  ...
}: let
  ai = import ./lib.nix {inherit config lib pkgs;};
  cfg = config.my.ai.pi;
  piCompatWrapper = pkgs.writeShellApplication {
    name = "pi";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.fd
      pkgs.ripgrep
    ];
    text = ''
      package_pi=${lib.escapeShellArg "${cfg.package}/bin/pi"}
      package_dir=${lib.escapeShellArg "${cfg.package}/libexec/pi"}
      standalone_pi="$package_dir/pi"
      system_loader=/lib/ld-linux-aarch64.so.1

      if [[ ! -x "$package_pi" ]]; then
        echo "pi: the Home Manager package is missing: $package_pi" >&2
        exit 127
      fi

      # llm-agents.nix's Bun standalone mixes the Nix loader with UOS libc on
      # aarch64. On UOS, start it with the host loader. NixOS ships a stub at
      # the same path (stub-ld), so exec the Nix-wrapped binary there instead.
      if [[ ! -e /etc/NIXOS && -x "$system_loader" && -x "$standalone_pi" ]]; then
        export PI_PACKAGE_DIR="$package_dir"
        export PI_SKIP_VERSION_CHECK=1
        export PI_TELEMETRY=0
        exec "$system_loader" "$standalone_pi" "$@"
      fi

      exec "$package_pi" "$@"
    '';
  };
  piDefaults = pkgs.writeText "pi-defaults.json" (builtins.toJSON {
    theme = "dark";
    defaultProvider = "openai-codex";
    defaultModel = "gpt-5.6-terra";
  });
in {
  config = lib.mkIf cfg.enable {
    home = {
      packages = [
        cfg.package
        (lib.hiPrio piCompatWrapper)
      ];
      activation.mergePiSettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
        ${ai.activationPreamble}
        ${ai.mergeJsonFile "${ai.homeDir}/.pi/agent/settings.json" piDefaults}
      '';
    };
  };
}
