{ pkgs, userSettings, ... }:

{
  home.packages = [ pkgs.git pkgs.lazygit ];
  programs.git.enable = true;
  programs.git.userName = userSettings.name;
  programs.git.userEmail = userSettings.email;
  programs.git.extraConfig = {
    init.defaultBranch = "main";
    safe.directory = [ ("/home/" + userSettings.username + "/.dotfiles")
                       ("/home/" + userSettings.username + "/.dotfiles/.git") ];
    merge.conflictstyle = "diff3";
    diff.colorMoved = "default";
    core = {
      whitespace = "trailing-space,space-before-tab";
    };
    url."ssh://git@github.com".insteadOf = "https://github.com";
  };
  programs.git.ignores = [
    "*~"
    "*.swp"
    ".direnv"
    ".devenv"
    ".build"
    "/result*"
    "/build/"
    "*.zwc"
  ];
  # programs.git.signing = {
  #   signer = "${pkgs.gnupg}/bin/gpg";
  #   key = "85602F353DA72853";
  #   # format = "openpgp";
  #   signByDefault = true;
  # };

  programs.git.delta = {
    enable = true;
    options = {
      line-numbers = true;
      side-by-side = true;
      diff-so-fancy = true;
      navigate = true;
    };
  };

  programs.gh = {
    enable = true;
    settings = {
      aliases = {
        co = "pr checkout";
        pv = "pr view";
      };
      editor = "hx";
      git-protocol = "ssh";
    };
    gitCredentialHelper = {
      enable = true;
      hosts = [
        "https://github.com"
        "https://gist.github.com"
        "https://gitlab.com"
        "https://gitee.com"
      ];
    };
  };

  programs.gpg.enable = true;
  programs.gpg.mutableTrust = false;
  programs.gpg.mutableKeys = false;
  programs.gpg.publicKeys = [
     {
        source = ./efwmc-gpg-keys-2025-07-31.pub;
        trust = 5;
     } # ultimate trust, my own keys.
  ];
  
}
