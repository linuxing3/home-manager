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

  programs.zsh = {
    enable = true;
    # autosuggestion.enable = true;
    # syntaxHighlighting.enable = true;
    # enableCompletion = true;
    shellAliases = myAliases;
    initContent = ''
      # Ensure Nix is loaded (for non-interactive or edge cases)
      if [ -z "''${__ETC_PROFILE_NIX_SOURCED:-}" ] && [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
        . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
      fi

      # Skip compinit insecure directories check (for non-NixOS systems)
      autoload -U compinit
      compinit -C

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

      # Prefer host ICD list, but auto-fallback to SwiftShader when Arise/Glenfly ICD is absent.
      SWIFTSHADER_ICD="${pkgs.swiftshader}/share/vulkan/icd.d/vk_swiftshader_icd.json"
      if [ -d /run/opengl-driver/share/vulkan/icd.d ]; then
        export VK_DRIVER_FILES="$(printf '%s:' /run/opengl-driver/share/vulkan/icd.d/*.json | sed 's/:$//')"
      elif [ -d /usr/share/vulkan/icd.d ]; then
        export VK_DRIVER_FILES="$(printf '%s:' /usr/share/vulkan/icd.d/*.json | sed 's/:$//')"
      fi
      if [ -n "$VK_DRIVER_FILES" ]; then
        export VK_ICD_FILENAMES="$VK_DRIVER_FILES"
      fi
      if [ "''${VK_FORCE_SWIFTSHADER:-0}" = "1" ]; then
        export VK_ICD_FILENAMES="$SWIFTSHADER_ICD"
      elif [ -n "$VK_ICD_FILENAMES" ] && ! echo "$VK_ICD_FILENAMES" | grep -Eqi '(arise|glenfly).*\.json'; then
        export VK_ICD_FILENAMES="$SWIFTSHADER_ICD"
      fi
      if [ -d /run/opengl-driver/share/vulkan/explicit_layer.d ]; then
        export VK_LAYER_PATH="$(printf '%s:' /run/opengl-driver/share/vulkan/explicit_layer.d/*.json | sed 's/:$//')"
      elif [ -d /usr/share/vulkan/explicit_layer.d ]; then
        export VK_LAYER_PATH="$(printf '%s:' /usr/share/vulkan/explicit_layer.d/*.json | sed 's/:$//')"
      fi

      # Load my api keys env when agenix has materialized the runtime file.
      if [ -f ${config.age.secrets."api-keys.age".path} ] && { [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ]; }; then
        eval "$(cat ${config.age.secrets."api-keys.age".path})"
      fi

      # Load my extra file when present
      [ -f ~/.config/zsh/extra/private.zsh ] && source ~/.config/zsh/extra/private.zsh

      ghostty() {
        GDK_BACKEND=x11 \
        GSK_RENDERER=cairo \
        LIBGL_ALWAYS_SOFTWARE=1 \
        MESA_LOADER_DRIVER_OVERRIDE=llvmpipe \
        GALLIUM_DRIVER=llvmpipe \
        command ghostty "$@"
      }
    '';
    # plugins = [
    #   {
    #     name = "fzf-tab";
    #     src = "${pkgs.zsh-fzf-tab}/share/fzf-tab";
    #   }
    #   {
    #     name = "vi-mode";
    #     src = "${pkgs.zsh-vi-mode}/share/zsh-vi-mode";
    #   }
    #   {
    #     name = "powerlevel10k";
    #     src = "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k";
    #   }
    # ];

  };

  programs.bash = {
    enable = true;
    enableCompletion = true;
    shellAliases = myAliases;
    initExtra = ''
      # Simple configuration
      PROMPT=" ◉ %U%F{magenta}%n%f%u@%U%F{blue}%m%f%u:%F{yellow}%~%f
       %F{green}→%f "
      RPROMPT="%F{red}▂%f%F{yellow}▄%f%F{green}▆%f%F{cyan}█%f%F{blue}▆%f%F{magenta}▄%f%F{white}▂%f"
      [ $TERM = "dumb" ] && PS1='$ '
    '';
    bashrcExtra = ''
      # gpg pinentry on tty
      export GPG_TTY="$(tty)"

      # Prefer host ICD list, but auto-fallback to SwiftShader when Arise/Glenfly ICD is absent.
      SWIFTSHADER_ICD="${pkgs.swiftshader}/share/vulkan/icd.d/vk_swiftshader_icd.json"
      if [ -d /run/opengl-driver/share/vulkan/icd.d ]; then
        export VK_DRIVER_FILES="$(printf '%s:' /run/opengl-driver/share/vulkan/icd.d/*.json | sed 's/:$//')"
      elif [ -d /usr/share/vulkan/icd.d ]; then
        export VK_DRIVER_FILES="$(printf '%s:' /usr/share/vulkan/icd.d/*.json | sed 's/:$//')"
      fi
      if [ -n "$VK_DRIVER_FILES" ]; then
        export VK_ICD_FILENAMES="$VK_DRIVER_FILES"
      fi
      if [ "''${VK_FORCE_SWIFTSHADER:-0}" = "1" ]; then
        export VK_ICD_FILENAMES="$SWIFTSHADER_ICD"
      elif [ -n "$VK_ICD_FILENAMES" ] && ! echo "$VK_ICD_FILENAMES" | grep -Eqi '(arise|glenfly).*\.json'; then
        export VK_ICD_FILENAMES="$SWIFTSHADER_ICD"
      fi
      if [ -d /run/opengl-driver/share/vulkan/explicit_layer.d ]; then
        export VK_LAYER_PATH="$(printf '%s:' /run/opengl-driver/share/vulkan/explicit_layer.d/*.json | sed 's/:$//')"
      elif [ -d /usr/share/vulkan/explicit_layer.d ]; then
        export VK_LAYER_PATH="$(printf '%s:' /usr/share/vulkan/explicit_layer.d/*.json | sed 's/:$//')"
      fi

      # Load my extra file when present
      [ -f ~/.config/bash/extra/private.bash ] && source ~/.config/bash/extra/private.bash

      ghostty() {
        GDK_BACKEND=x11 \
        GSK_RENDERER=cairo \
        LIBGL_ALWAYS_SOFTWARE=1 \
        MESA_LOADER_DRIVER_OVERRIDE=llvmpipe \
        GALLIUM_DRIVER=llvmpipe \
        command ghostty "$@"
      }
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
    # console
    antibody
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
  ];
}
