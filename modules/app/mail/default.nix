{ config, pkgs, userSettings, ... }:
{
  imports = [
    ./mfa.nix
    ./qq.nix
  ];

  accounts.email = {
    maildirBasePath = ".local/share/mail";
  };

  programs.mu = {
    enable = true;
  };

  programs.neomutt = {
    enable = true;
    vimKeys = true;
    extraConfig = ''
      set mailcap_path = "~/.config/neomutt/mailcap"
      source "~/.config/neomutt/private"
      set sendmail='msmtp'
    '';
  };

  programs.mbsync.enable = true;

  programs.himalaya.enable = true;

  systemd.user.services.qq-mail-sync = {
    Unit = {
      Description = "Sync QQ mail via mbsync and refresh mu index";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };

    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.zsh}/bin/zsh -ilc '${pkgs.isync}/bin/mbsync qq && ${pkgs.mu}/bin/mu index'";
    };
  };

  systemd.user.timers.qq-mail-sync = {
    Unit = {
      Description = "Run QQ mail sync periodically";
    };

    Timer = {
      OnBootSec = "2m";
      OnUnitActiveSec = "10m";
      Unit = "qq-mail-sync.service";
    };

    Install = {
      WantedBy = [ "timers.target" ];
    };
  };

  home.file.".msmtprc".text = ''
    # Set default values for all following accounts.
    defaults
    auth           on
    tls            on
    tls_trust_file /etc/ssl/certs/ca-certificates.crt
    logfile        ~/.msmtp.log

    # qq
    account        qq
    host           smtp.qq.com
    port           465
    tls_starttls   off
    from           ${userSettings.email}
    user           ${userSettings.nickname}
    passwordeval   cat ${config.age.secrets."mail-qq-pass.age".path}

    # mfa
    account        mfa
    host           mail.mfa.gov.cn
    port           465
    tls_starttls   off
    from           xing_wenju@mfa.gov.cn
    user           xing_wenju@mfa.gov.cn
    passwordeval   cat ${config.age.secrets."mail-mfa-pass.age".path}

    # Set a default account
    account default: qq
  '';
}
