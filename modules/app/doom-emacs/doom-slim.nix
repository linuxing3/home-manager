{
  config,
  lib,
  pkgs,
  userSettings,
  ...
}:
let
  themePolarity = lib.removeSuffix "\n" (builtins.readFile (./. + "../../../../themes"+("/"+userSettings.theme)+"/polarity.txt"));
  dashboardLogo = ./. + "/nix-" + themePolarity + ".webp";
in
   {
  home.file.".config/doom/themes/doom-stylix-theme.el".source = config.lib.stylix.colors {
    template = builtins.readFile ./themes/doom-stylix-theme.el.mustache;
    extension = ".el";
  };

  home.file.".config/doom/dashboard-logo.webp".source = dashboardLogo;

  home.packages =
    (with pkgs; [
      emacs-lsp-booster
      nil
      alejandra
      kotlin-language-server
      file
      wmctrl
      jshon
      aria
      hledger
      hunspell
      hunspellDicts.en_US-large
      mu
      (pkgs.callPackage ./pkgs/org-analyzer.nix {})
      isync
      msmtp
      getmail6

      libevdev
      libinput
      udev

      uv
      aider-chat
      (python3.withPackages (
        p:
          with p; [
            pandas
            requests
            epc
            lxml
            pysocks
            pymupdf
            pygetwindow
            pyqtwebengine
            pyqt5
            pyqt5-sip
            markdown
            orgparse
            ipython
          ]
      ))
    ])
    ++ (with pkgs; [
      nodejs
      nodePackages.mermaid-cli
    ])
    ++ (with pkgs; [
      openssl
      stunnel
    ]);

  services.mbsync = {
    enable = true;
    package = pkgs.isync;
    frequency = "*:0/5";
  };

  home.file.".config/getmail/getmailrc".text = ''
    [retriever]
    type = SimplePOP3SSLRetriever
    server = mail.mfa.gov.cn
    port = 995
    ssl_version = tlsv1_2
    ssl_ciphers = AES128-SHA

    username = xing_wenju@mfa.gov.cn
    password_command = ('cat', '${config.age.secrets."mail-mfa-pass.age".path}')

    [destination]
    type = Maildir
    path = /home/efwmc/.local/mail/mfa/Inbox/

    [options]
    delete = false
    read_all = false
  '';

  home.file.".config/msmtp/config".text = ''
    # Set default values for all following accounts.
    defaults
    port 465
    tls on
    tls_starttls off
    tls_trust_file   /etc/ssl/certs/ca-certificates.crt

    # account qq
    account qq
    user linuxing3
    from linuxing3@qq.com
    host smtp.qq.com
    auth on
    passwordeval cat ${config.age.secrets."mail-qq-pass.age".path}

    account default: qq
  '';

  home.file.".config/isyncrc".text = ''
    IMAPAccount qq
    Host imap.qq.com
    Port 993
    User linuxing3
    PassCmd "cat ${config.age.secrets."mail-qq-pass.age".path}"
    TLSType IMAPS
    CertificateFile /etc/ssl/certs/ca-certificates.crt

    IMAPStore qq-remote
    Account qq

    MaildirStore qq-local
    SubFolders Verbatim
    Path ~/.local/mail/qq/
    Inbox ~/.local/mail/qq/Inbox
    Trash ~/.local/mail/qq/Trash

    Channel qq
    Far :qq-remote:
    Near :qq-local:
    Patterns *
    SyncState *
    Create Both
    Expunge Both
    CopyArrivalDate yes
    Sync All
  '';

}
