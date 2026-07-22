{config, userSettings, ...}: let
  address = "xing_wenju@mfa.gov.cn";
  host = "mail.mfa.gov.cn";
  realName = userSettings.realname;
  accountConfig = ''
    [retriever]
    type = SimplePOP3SSLRetriever
    server = ${host}
    port = 995
    ssl_version = tlsv1_2
    ssl_ciphers = AES128-SHA

    username = ${address}
    password_command = ("cat", "${config.age.secrets."mail-mfa-pass.age".path}")

    [destination]
    type = Maildir
    path = ${config.home.homeDirectory}/.local/share/mail/mfa/Inbox/

    [options]
    delete = false
    read_all = false
  '';
in {
  accounts.email = {
    accounts = {
      mfa = {
        primary = false;
        address = address;
        userName = address;
        realName = realName;
        passwordCommand = "cat ${config.age.secrets."mail-mfa-pass.age".path}";
        imap.host = host;
        imap.tls.useStartTls = true;
        smtp.host = host;
        smtp.tls.useStartTls = true;
        neomutt.enable = true;
        neomutt.sendMailCommand = "msmtp";
        msmtp.enable = true;
      };
    };
  };
  home.file.".config/getmail/getmailrc".text = accountConfig;
}
