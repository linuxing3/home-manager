{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.features.home.qqMailNotion;
  # Agenix mounts secrets under $XDG_RUNTIME_DIR at login; read them at run time
  # so neither the QQ code nor the Notion key ever enters the store or the unit.
  agenixDir = ''"''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/agenix"'';
  qqPass = pkgs.writeShellApplication {
    name = "qq-mail-notion-pass";
    runtimeInputs = [pkgs.coreutils];
    text = ''exec head -n1 ${agenixDir}/mail-qq-pass.age'';
  };
  # IMAP only, no SMTP section: this himalaya config cannot send mail.
  himalayaConfig = pkgs.writeText "qq-mail-notion-himalaya.toml" ''
    [accounts.qq]
    default = true
    email = "${cfg.address}"
    backend.type = "imap"
    backend.host = "imap.qq.com"
    backend.port = 993
    backend.encryption.type = "tls"
    backend.login = "${cfg.address}"
    backend.auth.type = "password"
    backend.auth.cmd = "${lib.getExe qqPass}"
  '';
  qqMailNotion = pkgs.writeShellApplication {
    name = "qq-mail-notion";
    runtimeInputs = [pkgs.python3 pkgs.himalaya];
    text = ''
      exec python3 ${./qq-mail-notion.py} \
        --himalaya-config ${himalayaConfig} \
        --database-id ${lib.escapeShellArg cfg.databaseId} \
        --keys-file ${agenixDir}/api-keys-new.age \
        "$@"
    '';
  };
in {
  options.my.features.home.qqMailNotion = {
    enable = lib.mkEnableOption "read-only QQ INBOX to Notion「QQ 邮件收件箱」 sync every 30 minutes";
    address = lib.mkOption {
      type = lib.types.str;
      default = "linuxing3@qq.com";
    };
    databaseId = lib.mkOption {
      type = lib.types.str;
      default = "3fc3ec2d-7aec-816d-9da6-f37c37b1f2bf";
      description = "Notion database「QQ 邮件收件箱」 under 生活 · 主公日常.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [qqMailNotion];

    systemd.user.services.qq-mail-notion = {
      Unit = {
        Description = "Read-only QQ INBOX to Notion (QQ 邮件收件箱)";
        After = ["agenix.service" "network-online.target"];
        Wants = ["agenix.service"];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${lib.getExe qqMailNotion} --days 2";
        TimeoutStartSec = "20min";
        NoNewPrivileges = true;
      };
    };

    systemd.user.timers.qq-mail-notion = {
      Unit.Description = "Run qq-mail-notion every 30 minutes";
      Timer = {
        OnCalendar = "*:0/30";
        RandomizedDelaySec = "2min";
        Persistent = true;
      };
      Install.WantedBy = ["timers.target"];
    };
  };
}
