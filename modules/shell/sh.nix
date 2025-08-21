{
  config,
  pkgs,
  lib,
  ...
}: let
  # My shell aliases
  myAliases = {
    syncuser = "phoenix sync user";
    syncsys = "phoenix sync system";
    c = "clear";
    ls = "eza --icons -l -T -L=1";
    tree = "eza --icons --tree --group-directories-first";
    cat = "bat";
    htop = "btm";
    fd = "fd -Lu";
    w3m = "w3m -no-cookie -v";
    neofetch = "disfetch";
    fetch = "disfetch";
    gitfetch = "onefetch";
    N = "sudo -E nnn -dH";
    "," = "comma";
  };

  sessionPath = [
    "$HOME/.bin"
    "$HOME/.local/bin"
    "$HOME/.config/zsh/bin"
    "$HOME/.config/emacs/bin"
    "$HOME/.config/helix/scripts"
    "$HOME/.config/nvim/scripts"
    "$HOME/.config/zide/bin"
    "$HOME/.config/nnn/plugins"
    "$HOME/.config/qutebrowser/userscripts"
    ".git/safe/../../bin"
  ];
in {
  home.sessionPath = sessionPath;

  home.sessionVariables = {
    NNN_OPENER = "nuke";
    NNN_FIFO = "/tmp/nnn.fifo";
    NNN_PLUG = "p:preview-tui;l:launch;n:nuke;r:fzcd;s:suedit";
  };

  programs.zsh = {
    enable = true;
    # enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;
    shellAliases = myAliases;
    initContent = ''

      eval $(cat ${config.age.secrets.api-keys.path})

      # Load my extra file
      source ~/.config/zsh/extra/private.zsh

      # disable p9k wizard
      POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true

      # Simple configuration
      PROMPT=" ◉ %U%F{magenta}%n%f%u@%U%F{blue}%m%f%u:%F{yellow}%~%f
       %F{green}→%f "
      RPROMPT="%F{red}▂%f%F{yellow}▄%f%F{green}▆%f%F{cyan}█%f%F{blue}▆%f%F{magenta}▄%f%F{white}▂%f"
      [ $TERM = "dumb" ] && unsetopt zle && PS1='$ '
      bindkey '^P' history-beginning-search-backward
      bindkey '^N' history-beginning-search-forward
    '';
    plugins = [
      {
        # Must be before plugins that wrap widgets, such as zsh-autosuggestions or fast-syntax-highlighting
        name = "fzf-tab";
        src = "${pkgs.zsh-fzf-tab}/share/fzf-tab";
      }
    ];

  };

  programs.bash = {
    enable = true;
    enableCompletion = true;
    shellAliases = myAliases;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    enableFishIntegration = true;

    defaultCommand = "fd --hidden --strip-cwd-prefix --exclude .git";
    fileWidgetOptions = [
      "--preview 'if [ -d {} ]; then eza --tree --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi'"
    ];
    changeDirWidgetCommand = "fd --type=d --hidden --strip-cwd-prefix --exclude .git";
    changeDirWidgetOptions = [
      "--preview 'eza --tree --color=always {} | head -200'"
    ];

    ## Theme
    defaultOptions = [
      "--color=fg:-1,fg+:#FBF1C7,bg:-1,bg+:#282828"
      "--color=hl:#98971A,hl+:#B8BB26,info:#928374,marker:#D65D0E"
      "--color=prompt:#CC241D,spinner:#689D6A,pointer:#D65D0E,header:#458588"
      "--color=border:#665C54,label:#aeaeae,query:#FBF1C7"
      "--border='double' --border-label='' --preview-window='border-sharp' --prompt='> '"
      "--marker='>' --pointer='>' --separator='─' --scrollbar='│'"
      "--info='right'"
    ];
  };
  home.packages = with pkgs; [
    disfetch
    lolcat
    cowsay
    onefetch
    gnugrep
    gnused
    bat
    eza
    bottom
    fd
    bc
    direnv
    nix-direnv
  ];

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };
}
