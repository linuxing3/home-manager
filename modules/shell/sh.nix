{
  config,
  pkgs,
  ...
}: let
  # My shell aliases
  myAliases = {
    syncuser = "home-manager switch --flake ${config.home.homeDirectory}/.config/home-manager -b b";
    syncsys = "sudo nixos-rebuild switch --flake ${config.home.homeDirectory}/.config/home-manager .#system";
    zx = "zellix";
    zj = "zellij";
    j = "just";
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
    ".." = "cd ..";
    "..." = "cd ../..";
  };

  sessionPath = [
    "$HOME/.bin"
    "$HOME/.local/bin"
    ".git/safe/../../bin"
  ];
  agenixEnv = pkgs.writeShellApplication {
    name = "agenix-env";
    runtimeInputs = [pkgs.bash];
    text = ''
      set -euo pipefail
      secret_file=${config.age.secrets."api-keys-new.age".path}
      if [[ ! -r "$secret_file" ]]; then
        echo "agenix-env: api-keys-new.age is not materialized; check the Agenix identity and user service" >&2
        exit 1
      fi
      if [[ "''${1:-}" != "--" || $# -lt 2 ]]; then
        echo "usage: agenix-env -- command [args...]" >&2
        exit 2
      fi
      shift
      exec ${pkgs.bash}/bin/bash -c 'set -a; . "$1"; shift; exec "$@"' agenix-env "$secret_file" "$@"
    '';
  };
  agentEnv = pkgs.writeShellApplication {
    name = "agent-env";
    runtimeInputs = [pkgs.coreutils];
    text = ''
      set -euo pipefail
      if [[ "''${1:-}" != "--" || $# -lt 2 ]]; then
        echo "usage: agent-env -- command [args...]" >&2
        exit 2
      fi
      shift
      command_name=$(basename -- "$1")
      case "$command_name" in
        git|gh|curl|wget|ssh|scp|rsync|codex|claude|opencode|hermes|jcode)
          exec ${agenixEnv}/bin/agenix-env -- "$@"
          ;;
        *)
          echo "agent-env: command is not allowlisted: $command_name" >&2
          exit 126
          ;;
      esac
    '';
  };
in {
  home.sessionPath = sessionPath;

  home.sessionVariables = {
    SHELL = "zsh";
    VISUAL = "hx";
    NNN_OPENER = "xnuke";
    NNN_FIFO = "/tmp/nnn.fifo";
    NNN_TMPFILE = "~/.config/nnn/.lastd";
    NNN_PLUG = "p:preview_tabbed;v:imgview;l:launch;n:xnuke;z:fzcd;s:suedit;r:gitroot;e:gpge;d:gpgd;s:gpgs;i:gpgv;g:-!git diff;";
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
    nix-direnv.enable = true;
  };

  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    flags = [
      "--disable-ctrl-r"
      "--disable-up-arrow"
    ];
  };

  programs.zsh = {
    enable = true;
    # autosuggestion.enable = true;
    # syntaxHighlighting.enable = true;
    enableCompletion = false;
    shellAliases = myAliases;
    initContent = ''
      # Ensure Nix is loaded (for non-interactive or edge cases)
      if [ -z "''${__ETC_PROFILE_NIX_SOURCED:-}" ] && [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
        . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
      fi

      # Skip compinit insecure directories check (for non-NixOS systems)
      autoload -U compinit
      compinit -C

      # Guard: when spawned from hermes runtime under /nix/store/.../site-packages,
      # reset interactive shells to HOME so startup is usable.
      if [[ -o interactive && "$PWD" == /nix/store/*/site-packages* ]]; then
        builtin cd "$HOME" 2>/dev/null || builtin cd /
      fi

      # Simple configuration
      PROMPT=" ◉ %U%F{magenta}%n%f%u@%U%F{blue}%m%f%u:%F{yellow}%~%f
       %F{green}→%f "
      RPROMPT="%F{red}▂%f%F{yellow}▄%f%F{green}▆%f%F{cyan}█%f%F{blue}▆%f%F{magenta}▄%f%F{white}▂%f"
      [ $TERM = "dumb" ] && unsetopt zle && PS1='$ '

      # key bindings
      bindkey '^P' history-beginning-search-backward
      bindkey '^N' history-beginning-search-forward

      # gpg pinentry on tty
      export GPG_TTY="$(tty)"

      # Load my extra file when present
      [ -f ~/.config/zsh/extra/private.zsh ] && source ~/.config/zsh/extra/private.zsh
    '';
  };

  programs.bash = {
    enable = true;
    enableCompletion = true;
    shellAliases = myAliases;
    bashrcExtra = ''
      # gpg pinentry on tty
      export GPG_TTY="$(tty)"

      # Load my extra file when present
      [ -f ~/.config/bash/extra/private.bash ] && source ~/.config/bash/extra/private.bash

    '';
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    enableFishIntegration = true;

    defaultCommand = "fd --hidden --strip-cwd-prefix --exclude .git";
    fileWidget.options = [
      "--preview 'if [ -d {} ]; then eza --tree --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi'"
    ];
    changeDirWidget.command = "fd --type=d --hidden --strip-cwd-prefix --exclude .git";
    changeDirWidget.options = [
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

  home.packages =
    [agenixEnv agentEnv]
    ++ (with pkgs; [
      # console
      patchelf
      nushell
      rio

      # rust cli
      sd
      xcp
      dysk
      delta
      dua
      dust
      erdtree
      lsd
      procs
      mcfly
      mdcat
      miniserve
      mise
      monolith
      mprocs
      ouch
      pastel
      qsv
      rnr
      ruff
      skim
      teehee
      watchexec
    ]);
}
