{
  pkgs,
  userSettings,
  ...
}:
{

  programs.lazygit.enable = true;
  programs.lazygit.settings = {
    gui = {
      theme = {
        lightTheme = true;
        activeBorderColor = [
          "blue"
          "bold"
        ];
        inactiveBorderColor = [ "black" ];
        selectedLineBgColor = [ "default" ];
      };
    };
  };

  programs.git.enable = true;
  programs.git.settings = {
    user = {
      name = userSettings.name;
      email = userSettings.email;
    };
    init.defaultBranch = "main";
    merge.conflictstyle = "diff3";
    diff.colorMoved = "default";
    core = {
      whitespace = "trailing-space,space-before-tab";
    };
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
    key = "8DB2F92A1DAB1EBB";
    format = "openpgp";
    signByDefault = false;
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

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
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
