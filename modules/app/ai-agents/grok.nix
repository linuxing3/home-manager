{
  config,
  lib,
  pkgs,
  ...
}: let
  ai = import ./lib.nix {inherit config lib pkgs;};
  globalAgents = pkgs.writeText "grok-AGENTS.md" ''
    ${builtins.readFile ./files/environment-rules.md}

    ${builtins.readFile ./files/notion-bootstrap.md}
  '';
  grokDefaults = pkgs.writeText "grok-defaults.json" (builtins.toJSON {
    memory.enabled = false;
    mcp_servers.notion = {
      url = "https://mcp.notion.com/mcp";
      enabled = true;
    };
  });
in {
  home.file.".grok/AGENTS.md".source = globalAgents;

  home.activation.mergeGrokConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${ai.activationPreamble}
    ${ai.mergeTomlFile "${ai.homeDir}/.grok/config.toml" grokDefaults}
  '';
}
