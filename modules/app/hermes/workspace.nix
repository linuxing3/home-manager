{ pkgs, ... }:
{
  systemd.user.services.hermes-workspace = {
    Unit = {
      Description = "Hermes Workspace production server";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };

    Service = {
      Type = "simple";
      WorkingDirectory = "/sources/hermes-workspace";
      ExecStart = "/usr/local/bin/pnpm run start";
      Restart = "on-failure";
      RestartSec = 2;
      Environment = [
        "NODE_ENV=production"
        "HOST=0.0.0.0"
        "PORT=3000"
      ];
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
