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
      ExecStartPre = "${pkgs.zsh}/bin/zsh -ilc 'pnpm build'";
      ExecStart = "${pkgs.zsh}/bin/zsh -ilc 'NODE_OPTIONS=\"--max-old-space-size=2048\" node server-entry.js'";
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
