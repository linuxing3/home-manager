{ config, pkgs, ... }:
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
    from           linuxing3@qq.com
    user           linuxing3
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
