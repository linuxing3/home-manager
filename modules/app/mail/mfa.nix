{config, ...}: let
  address = "xing_wenju@mfa.gov.cn";
  host = "mail.mfa.gov.cn";
  realName = "Xing Wenju";
  accountConfig = ''
    [retriever]
    type = SimplePOP3SSLRetriever
    server = mail.mfa.gov.cn
    port = 995
    ssl_version = tlsv1_2
    ssl_ciphers = AES128-SHA

    username = xing_wenju@mfa.gov.cn
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
