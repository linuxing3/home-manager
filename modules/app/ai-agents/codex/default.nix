{
  config,
  lib,
  pkgs,
  ...
}: let
  ai = import ../lib.nix {inherit config lib pkgs;};
  mcp = import ../mcp-lib.nix {inherit config lib pkgs;};
  fffBin = "${ai.profileBin}/fff-mcp";
  codexAgents = pkgs.writeText "codex-AGENTS.md" ''
    ${builtins.readFile ./files/AGENTS.md}

    ${builtins.readFile ../files/notion-bootstrap.md}
  '';
  codexDefaults = pkgs.writeText "codex-defaults.json" (builtins.toJSON {
    model = "codex/gpt-5.6-sol";
    model_provider = "magpie";
    approval_policy = "never";
    sandbox_mode = "danger-full-access";
    model_reasoning_effort = "high";
    plan_mode_reasoning_effort = "high";
    # Magpie serves the Responses API on its keyless loopback gateway.
    model_providers.magpie = {
      name = "magpie";
      base_url = "http://127.0.0.1:${toString config.my.ai.magpieGateway.gatewayPort}/v1";
      wire_api = "responses";
      requires_openai_auth = false;
    };
    features = {
      hooks = true;
      memories = false;
    };
    tui.vim_mode_default = true;
    mcp_servers = {
      fff.command = "${ai.homeDir}/.nix-profile/bin/fff-mcp";
      gdrive = mcp.gdrive;
      canva = mcp.canva;
      notion = mcp.notion;
      obscura = {
        command = "obscura";
        args = ["mcp"];
      };
    };
  });
in {
  home.file = {
    ".codex/AGENTS.md".source = codexAgents;
    ".codex/hooks.json".source = files/hooks.json;
    ".codex/herdr-agent-state.sh" = {
      source = files/herdr-agent-state.sh;
      executable = true;
    };
  };

  home.activation.mergeCodexConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${ai.activationPreamble}
    ${ai.mergeTomlFile "${ai.homeDir}/.codex/config.toml" codexDefaults}
    ${pkgs.yq}/bin/tomlq --toml-output --in-place \
      'del(.model_providers.cliproxyapi, .model_providers.jev)' \
      ${lib.escapeShellArg "${ai.homeDir}/.codex/config.toml"}
  '';

  home.activation.configureCodexTools = lib.hm.dag.entryAfter ["installPackages" "linkGeneration"] ''
    export HOME=${lib.escapeShellArg ai.homeDir}
    export RTK_TELEMETRY_DISABLED=1

    rtk_bin=${lib.escapeShellArg "${pkgs.rtk}/bin/rtk"}
    codex_bin=${lib.escapeShellArg "${ai.profileBin}/codex"}
    fff_bin=${lib.escapeShellArg fffBin}

    for executable in "$rtk_bin" "$fff_bin"; do
      if [[ ! -x "$executable" ]]; then
        echo "codex activation: required executable is missing: $executable" >&2
        exit 1
      fi
    done

    if [[ -x "$codex_bin" ]]; then
      "$rtk_bin" init -g --codex

      if ! "$codex_bin" mcp get fff --json 2>/dev/null |
        ${pkgs.jq}/bin/jq -e --arg command "$fff_bin" '.transport.command == $command' >/dev/null; then
        "$codex_bin" mcp remove fff >/dev/null 2>&1 || true
        "$codex_bin" mcp add fff -- "$fff_bin"
      fi
    else
      echo "codex activation: skipping Codex integration; missing $codex_bin" >&2
    fi
  '';
}
