{
  config,
  lib,
  pkgs,
  ...
}: let
  ai = import ./lib.nix {inherit config lib pkgs;};
  nodeLoopbackListen = pkgs.writeText "node-loopback-listen.cjs" ''
    const net = require("node:net");
    const originalListen = net.Server.prototype.listen;

    net.Server.prototype.listen = function (...args) {
      if (typeof args[0] === "number") {
        const hasHost = typeof args[1] === "string";
        if (!hasHost) {
          const callback = typeof args[1] === "function" ? args.splice(1, 1)[0] : undefined;
          args.splice(1, 0, "127.0.0.1");
          if (callback) args.push(callback);
        }
      }
      return originalListen.apply(this, args);
    };
  '';
in {
  xdg.configFile = {
    "systemd/user/default.target.wants/cloudflared-cursor-openai.service".force = true;
    "systemd/user/default.target.wants/cursor-to-openai.service".force = true;
  };

  systemd.user.services = {
    cloudflared-cursor-openai = {
      Unit = {
        Description = "Cloudflare Tunnel for Cursor-to-OpenAI";
        After = ["network-online.target"];
        Wants = ["network-online.target"];
        ConditionPathExists = "${ai.homeDir}/.cloudflared/cursor-openai.yml";
      };
      Service =
        ai.serviceHardening
        // {
          Type = "simple";
          ExecStart = "${pkgs.cloudflared}/bin/cloudflared --no-autoupdate tunnel --config ${ai.homeDir}/.cloudflared/cursor-openai.yml run cursor-openai";
          Restart = "on-failure";
          RestartSec = 5;
        };
      Install.WantedBy = ["default.target"];
    };

    cursor-to-openai = {
      Unit = {
        Description = "Cursor To OpenAI on loopback port 3010";
        After = ["network.target"];
        ConditionPathExists = "/share/data/sources/cursor-to-openai/package.json";
      };
      Service =
        ai.serviceHardening
        // {
          Type = "simple";
          WorkingDirectory = "/share/data/sources/cursor-to-openai";
          EnvironmentFile = "${ai.configHome}/cursor-to-openai.env";
          Environment = [
            "PORT=3010"
            "PATH=${ai.profileBin}:/usr/bin:/bin"
          ];
          ExecStart = "${ai.profileBin}/node --require ${nodeLoopbackListen} src/app.js";
          Restart = "on-failure";
          RestartSec = 5;
        };
      Install.WantedBy = ["default.target"];
    };
  };
}
