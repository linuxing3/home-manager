{
  config,
  lib,
  pkgs,
  inputs,
  userSettings,
  systemSettings,
  ...
}: let
  themePolarity = lib.removeSuffix "\n" (
    builtins.readFile (./. + "../../../../themes" + ("/" + userSettings.theme) + "/polarity.txt")
  );
  dashboardLogo = ./. + "/nix-" + themePolarity + ".webp";
in {
  imports = [
    inputs.nix-doom-emacs.hmModule
    ../git/git.nix
    ../../shell/sh.nix
    ../../shell/cli-collection.nix
  ];

  home.file.".config/doom/themes/doom-stylix-theme.el".source = config.lib.stylix.colors {
    template = builtins.readFile ./themes/doom-stylix-theme.el.mustache;
    extension = ".el";
  };

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
      emacsPackages.mu4e
      isync
      msmtp

      libevdev
      libinput
      udev

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

  home.file.".config/doom/org-yaap" = {
    source = "${inputs.org-yaap}";
    recursive = true;
  };

  home.file.".config/doom/org-side-tree" = {
    source = "${inputs.org-side-tree}";
    recursive = true;
  };

  home.file.".config/doom/org-timeblock" = {
    source = "${inputs.org-timeblock}";
    recursive = true;
  };

  home.file.".config/doom/org-nursery" = {
    source = "${inputs.org-nursery}";
  };

  home.file.".config/doom/org-krita" = {
    source = "${inputs.org-krita}";
  };

  home.file.".config/doom/org-xournalpp" = {
    source = "${inputs.org-xournalpp}";
  };

  home.file.".config/doom/org-sliced-images" = {
    source = "${inputs.org-sliced-images}";
  };

  home.file.".config/doom/magit-file-icons" = {
    source = "${inputs.magit-file-icons}";
  };

  home.file.".config/doom/dashboard-logo.webp".source = dashboardLogo;
  home.file.".config/doom/scripts/copy-link-or-file/copy-link-or-file-to-clipboard.sh" = {
    source = ./scripts/copy-link-or-file/copy-link-or-file-to-clipboard.sh;
    executable = true;
  };

  home.file.".config/doom/phscroll" = {
    source = "${inputs.phscroll}";
  };

  home.file.".config/doom/mini-frame" = {
    source = "${inputs.mini-frame}";
  };

  home.file.".config/getmail/getmailrc".text = ''
    [retriever]
    type = SimplePOP3SSLRetriever
    server = mail.mfa.gov.cn
    port = 995
    ssl_version = tlsv1_2
    ssl_ciphers = AES128-SHA

    username = xing_wenju@mfa.gov.cn
    password_command = ('cat', '/etc/agenix/mail-mfa-pass')

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
    passwordeval cat /etc/agenix/mail-qq-pass

    account default: qq
  '';

  home.file.".config/isyncrc".text = ''
    IMAPAccount qq
    Host imap.qq.com
    Port 993
    User linuxing3
    PassCmd "cat /etc/agenix/mail-qq-pass"
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

  home.file.".config/doom/system-vars.el".text =
    ''
      ;;; ~/.config/doom/~/.config/doom/config.el -*- lexical-binding: t; -*-

      ;; Import relevant variables from flake into emacs

      (setq user-full-name "''
    + userSettings.name
    + ''
      ") ; name
        (setq user-username "''
    + userSettings.username
    + ''
      ") ; username
        (setq user-mail-address "''
    + userSettings.email
    + ''
      ") ; email
        (setq user-home-directory "/home/''
    + userSettings.username
    + ''
      ") ; absolute path to home directory as string
        (setq user-default-roam-dir "''
    + userSettings.defaultRoamDir
    + ''
      ") ; absolute path to home directory as string
        (setq system-nix-profile "''
    + systemSettings.profile
    + ''
      ") ; what profile am I using?
        (setq system-wm-type "''
    + userSettings.wmType
    + ''
      ") ; wayland or x11?
        (setq doom-font (font-spec :family "''
    + userSettings.font
    + ''
      " :size 20)) ; import font
        (setq dotfiles-dir "''
    + userSettings.dotfilesDir
    + ''
      ") ; import location of dotfiles directory
    '';
}
