{
  config,
  lib,
  pkgs,
  ...
}: let
  ai = import ./lib.nix {inherit config lib pkgs;};
  cfg = config.my.ai.cliProxyApi;
  cliProxyDefaults = pkgs.writeText "cli-proxy-defaults.json" (builtins.toJSON {
    host = "127.0.0.1";
    port = 8317;
    tls = {
      enable = false;
      cert = "";
      key = "";
    };
    auth-dir = "${ai.homeDir}/.cli-proxy-api";
    debug = false;
    pprof = {
      enable = false;
      addr = "127.0.0.1:8316";
    };
    commercial-mode = false;
    logging-to-file = false;
    logs-max-total-size-mb = 0;
    error-logs-max-files = 10;
    usage-statistics-enabled = false;
    passthrough-headers = false;
    request-retry = 3;
    max-retry-credentials = 0;
    max-retry-interval = 30;
    disable-cooling = false;
    save-cooldown-status = false;
    transient-error-cooldown-seconds = 0;
    disable-image-generation = false;
    quota-exceeded = {
      switch-project = true;
      switch-preview-model = true;
      antigravity-credits = true;
    };
    routing = {
      strategy = "round-robin";
      session-affinity = false;
      session-affinity-ttl = "1h";
    };
    ws-auth = true;
    nonstream-keepalive-interval = 0;
  });
in {
  imports = [../cli-proxy-api/default.nix];

  config = lib.mkIf cfg.enable {
    home.packages = [cfg.package];

    xdg.configFile."systemd/user/default.target.wants/cli-proxy-api.service".force = true;

    home.activation.mergeCliProxyConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
      ${ai.activationPreamble}
      ${ai.ensureAndMergeYamlFile "${ai.homeDir}/.cli-proxy-api/config.yaml" cliProxyDefaults ". * $defaults[0]"}
    '';
  };
}
