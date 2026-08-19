{
  config,
  lib,
  pkgs,
  ...
}: let
  ai = import ../lib.nix {inherit config lib pkgs;};
  cfg = config.my.ai.herdr;
  pluginsManifest = pkgs.writeText "herdr-plugins.json" (builtins.toJSON {
    version = 1;
    github = cfg.plugins;
    local = cfg.localPlugins;
  });
  pluginBuildInputs = with pkgs; [
    rustc
    cargo
    gcc
    pkg-config
  ];
  herdrPluginSync = pkgs.writeShellApplication {
    name = "herdr-plugin-sync";
    runtimeInputs = [pkgs.python3] ++ pluginBuildInputs;
    text = ''
      export CARGO_HOME="''${CARGO_HOME:-${config.xdg.cacheHome}/herdr-plugin-cargo}"
      exec ${pkgs.python3}/bin/python3 ${./plugin-sync.py} \
        ${pluginsManifest} ${lib.escapeShellArg "${cfg.package}/bin/herdr"}
    '';
  };
  herdrAgentRename = pkgs.writeShellApplication {
    name = "herdr-agent-rename";
    text = ''
      pane_id="''${HERDR_ACTIVE_PANE_ID:-''${HERDR_PANE_ID:-}}"
      if [[ -z "$pane_id" ]]; then
        echo "herdr-agent-rename: no active Herdr pane was provided" >&2
        exit 1
      fi

      read -r -p "Agent name: " agent_name
      if [[ ! "$agent_name" =~ ^[a-z][a-z0-9_-]{0,31}$ ]]; then
        echo "Invalid name: use 1-32 lowercase letters, digits, _ or -, starting with a letter." >&2
        read -r -p "Press Enter to close..." _
        exit 2
      fi

      herdr_bin="''${HERDR_BIN_PATH:-${cfg.package}/bin/herdr}"
      "$herdr_bin" agent rename "$pane_id" "$agent_name"
      echo
      echo "Agent renamed to $agent_name."
      read -r -p "Press Enter to close..." _
    '';
  };
in {
  imports = [../../../tui/nnn-herdr-sync.nix];

  config = lib.mkIf cfg.enable {
    home.packages = [
      cfg.package
      herdrAgentRename
      herdrPluginSync
      pkgs.helix
      pkgs.xclip
    ];

    xdg.configFile."herdr/config.toml".source = files/config.toml;
    xdg.configFile."herdr-hx/config.toml".text = ''
      [sidebar]
      hx_bin = "${lib.getExe pkgs.helix}"
    '';

    home.activation.installHerdrPlugins = lib.mkIf cfg.installPlugins (
      lib.hm.dag.entryAfter ["installPackages"] ''
        ${ai.activationPreamble}
        export PATH=${lib.makeBinPath ([cfg.package] ++ pluginBuildInputs)}:$PATH
        export CARGO_HOME=${lib.escapeShellArg "${config.xdg.cacheHome}/herdr-plugin-cargo"}
        run ${herdrPluginSync}/bin/herdr-plugin-sync
      ''
    );
  };
}
