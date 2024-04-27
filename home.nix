{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "vagrant";
  home.homeDirectory = "/home/vagrant";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "23.11"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = [
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    pkgs.broot
    pkgs.ranger

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    (pkgs.writeShellScriptBin "tile" ''
      echo "Welcome to tile, ${config.home.username}!"
      cmd=$(which tmux)
      session=workspace
      $cmd has -t $session
      if [ $? != 0 ]; then
        $cmd new -d -n bash -s $session "hx"
        $cmd neww -n bash -s $session "bash"
        $cmd neww -n bash -s $session "bash"
        $cmd neww -n bash -s $session "bash"
        $cmd selectw -t session:1
      fi
      $cmd att -t $session
      exit 0
    '')
    (pkgs.writeShellScriptBin "deploy" ''
      git add .
      git commit -m "[feat] no description"
      git push
      exit 0
    '')
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # ".profile".source = dotfiles/.profile;

    ".tmux.conf".source = dotfiles/.tmux.conf;

    ".config/helix/config.toml".source = dotfiles/helix/config.toml;

    ".gitconfig".source = chezmoi/dot_gitconfig.tmpl;
    ".config/starship.toml".source = chezmoi/dot_config/starship.toml;
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. If you don't want to manage your shell through Home
  # Manager then you have to manually source 'hm-session-vars.sh' located at
  # either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/vagrant/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    EDITOR = "hx";
  };

  home.shellAliases = {
    g = "git";
    ".." = "cd ../";
    "..." = "cd ../..";
    vi = "hx";
    vim = "hx";
    nano = "hx";
    c = "clear";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs = {
      direnv = {
        enable = true;
        enableBashIntegration = true; # see note on other shells below
        nix-direnv.enable = true;
      };

      bash = {
        enable = true;
      };

      zsh = {
        enable = true;
      };

      nushell = { 
        enable = true;
        # for editing directly to config.nu 
        extraConfig = ''
         let carapace_completer = {|spans|
         carapace $spans.0 nushell $spans | from json
         }
         $env.config = {
          show_banner: false,
          completions: {
          case_sensitive: false # case-sensitive completions
          quick: true    # set to false to prevent auto-selecting completions
          partial: true    # set to false to prevent partial filling of the prompt
          algorithm: "fuzzy"    # prefix or fuzzy
          external: {
          # set to false to prevent nushell looking into $env.PATH to find more suggestions
              enable: true 
          # set to lower can improve completion performance at the cost of omitting some options
              max_results: 100 
              completer: $carapace_completer # check 'carapace_completer' 
            }
          }
         } 
         $env.PATH = ($env.PATH | 
         split row (char esep) |
         prepend /home/myuser/.apps |
         append /usr/bin/env
         )
         '';
         shellAliases = {
         vi = "hx";
         vim = "hx";
         nano = "hx";
         };
     };  

     carapace.enable = true;
     carapace.enableNushellIntegration = true;

     starship = { 
      enable = true;
    };

     gh =  {
      enable = true;
      settings = {
        git_protocol = "ssh";
        prompt = "enabled";
        aliases = {
          co = "pr checkout";
          pv = "pr view";
        };
      };
    };

  };

}
