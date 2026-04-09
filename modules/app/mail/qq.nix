{ config,...}: let
in {

  accounts.email = {

    accounts = {
      qq = {
        primary = true;
        address = "linuxing3@qq.com";
        userName = "linuxing3";
        realName = "Xing Wenju";
        maildir = {
          path = "qq";
        };
        passwordCommand = "cat ${config.age.secrets."mail-qq-pass.age".path}";
        imap.port = 993;
        imap.host = "imap.qq.com";
        imap.tls.useStartTls = true;
        smtp.port = 465;
        smtp.host = "smtp.qq.com";
        smtp.tls.useStartTls = true;
        msmtp.enable = true;
        neomutt.enable = true;
        neomutt.sendMailCommand = "msmtp";
        himalaya.enable = true;
        mbsync = {
          enable = true;
          create = "maildir";
          extraConfig = {
            account = {
              TLSType = "IMAPS";
              PipelineDepth = 10;
              Timeout = 60;
            };
          };
        };
      };
    };
  };

}
