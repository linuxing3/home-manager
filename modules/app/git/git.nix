{ pkgs, userSettings, ... }:
{
  home.packages = [ pkgs.git pkgs.lazygit ];

  programs.lazygit.enable = true;
  programs.lazygit.settings = {
    gui = {
      theme = {
        lightTheme = true;
        activeBorderColor = [ "blue" "bold" ];
        inactiveBorderColor = [ "black" ];
        selectedLineBgColor = [ "default" ];
      };
    };
  };

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

  programs.git.signing = {
    signer = "gpg";
    key = "57FB1A38C180FACA";
    format = "openpgp";
    signByDefault = true;
  };

  programs.gpg.enable = true;
  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    pinentry.package = pkgs.pinentry-curses;
    extraConfig = ''
      allow-loopback-pinentry
    '';
  };

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

}
