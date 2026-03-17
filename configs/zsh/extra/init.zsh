PERSIST=/persistent/home/linuxing3
PATH=$PERSIST/.config/zide/bin:$PERSIST/.config/emacs/bin:$HOME/.local/bin:$PATH

POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true

alias reload="source $HOME/.config/zsh/extra/init.zsh"

alias reswitch="sudo nixos-rebuild switch --impure --flake $HOME/sources/pure-nixos"
alias rebuild="sudo nixos-rebuild build --impure --flake $HOME/sources/pure-nixos"

alias ~~="cd $PERSIST"
alias ~c="cd $PERSIST/.config"
alias ~s="cd $PERSIST/sources"
alias ~o="cd $PERSIST/OneDrive/org"

# Utils
alias c="clear"
alias cd="z"
alias cat="bat"
alias nano="micro"
alias diff="delta --diff-so-fancy --side-by-side"
alias less="bat"
alias y="yazi"
alias py="python"
alias ipy="ipython"
alias icat="kitten icat"
alias dsize="du -hs"
alias pdf="tdf"
alias open="xdg-open"
alias space="ncdu"
alias man="BAT_THEME='default' batman"

alias l="eza --icons  -a --group-directories-first -1" # EZA_ICON_SPACING=2
alias ll="eza --icons  -a --group-directories-first -1 --no-user --long"
alias tree="eza --icons --tree --group-directories-first"

alias piv="python -m venv .venv"
alias psv="source .venv/bin/activate"

alias vvv="nix run github:fred-drake/neovim#"

alias kkk="sudo pkill kmscon"
    

# Use emacs key bindings
# Set terminal type explicitly
if [[ "$TERM" == "linux" ]] then
  export TERM=xterm-256color
fi
bindkey -e
# Ensure proper backspace behavior
bindkey "^?" backward-delete-char
bindkey "^H" backward-delete-char
bindkey "^[[3~" delete-char  # Ensure delete key works
WORDCHARS='~!#$%^&*(){}[]<>?.+-'
""{back,for}ward-word() WORDCHARS=$MOTION_WORDCHARS zle .$WIDGET
zle -N backward-word
zle -N forward-word
# [PageUp] - Up a line of history
if [[ -n "''${terminfo[kpp]}" ]] then
  bindkey -M emacs "''${terminfo[kpp]}" up-line-or-history
  bindkey -M viins "''${terminfo[kpp]}" up-line-or-history
  bindkey -M vicmd "''${terminfo[kpp]}" up-line-or-history
fi
# [PageDown] - Down a line of history
if [[ -n "''${terminfo[knp]}" ]] then
  bindkey -M emacs "''${terminfo[knp]}" down-line-or-history
  bindkey -M viins "''${terminfo[knp]}" down-line-or-history
  bindkey -M vicmd "''${terminfo[knp]}" down-line-or-history
fi
# Start typing + [Up-Arrow] - fuzzy find history forward
autoload -U up-line-or-beginning-search
zle -N up-line-or-beginning-search
bindkey -M emacs "^[[A" up-line-or-beginning-search
bindkey -M viins "^[[A" up-line-or-beginning-search
bindkey -M vicmd "^[[A" up-line-or-beginning-search
if [[ -n "''${terminfo[kcuu1]}" ]] then
  bindkey -M emacs "''${terminfo[kcuu1]}" up-line-or-beginning-search
  bindkey -M viins "''${terminfo[kcuu1]}" up-line-or-beginning-search
  bindkey -M vicmd "''${terminfo[kcuu1]}" up-line-or-beginning-search
fi
# Start typing + [Down-Arrow] - fuzzy find history backward
autoload -U down-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey -M emacs "^[[B" down-line-or-beginning-search
bindkey -M viins "^[[B" down-line-or-beginning-search
bindkey -M vicmd "^[[B" down-line-or-beginning-search
if [[ -n "''${terminfo[kcud1]}" ]] then
  bindkey -M emacs "''${terminfo[kcud1]}" down-line-or-beginning-search
  bindkey -M viins "''${terminfo[kcud1]}" down-line-or-beginning-search
  bindkey -M vicmd "''${terminfo[kcud1]}" down-line-or-beginning-search
fi
# [Ctrl-Delete] - delete whole forward-word
bindkey -M emacs '^[[35~' kill-word
bindkey -M viins '^[[35~' kill-word
bindkey -M vicmd '^[[35~' kill-word
# [Ctrl-RightArrow] - move forward one word
bindkey -M emacs '^[[15C' forward-word
bindkey -M viins '^[[15C' forward-word
bindkey -M vicmd '^[[15C' forward-word
# [Ctrl-LeftArrow] - move backward one word
bindkey -M emacs '^[[15D' backward-word
bindkey -M viins '^[[15D' backward-word
bindkey -M vicmd '^[[15D' backward-word
bindkey '\ew' kill-region                             # [Esc-w] - Kill from the cursor to the mark
bindkey -s '\el' 'ls\n'                               # [Esc-l] - run command: ls
bindkey ' ' magic-space                               # [Space] - don't do history expansion
# Edit the current command line in $EDITOR
autoload -U edit-command-line
zle -N edit-command-line
bindkey '\C-x\C-e' edit-command-line
# file rename magick
bindkey "^[m" copy-prev-shell-word
# This will be our new default `ctrl+w` command
my-backward-delete-word() {
    # Copy the global WORDCHARS variable to a local variable. That way any
    # modifications are scoped to this function only
    local WORDCHARS=$WORDCHARS
    # Use bash string manipulation to remove `:` so our delete will stop at it
    WORDCHARS="''${WORDCHARS//:}"
    # Use bash string manipulation to remove `/` so our delete will stop at it
    WORDCHARS="''${WORDCHARS//\/}"
    # Use bash string manipulation to remove `.` so our delete will stop at it
    WORDCHARS="''${WORDCHARS//.}"
    WORDCHARS="''${WORDCHARS//-}"
    # zle <widget-name> will run an existing widget.
    zle backward-delete-word
}
# `zle -N` will create a new widget that we can use on the command line
zle -N my-backward-delete-word
# bind this new widget to `ctrl+w`
bindkey '^W' my-backward-delete-word

# starship preset gruvbox-rainbow > $HOME/.config/starship.toml
# eval "$(starship init zsh)"
# eval "$(zoxide init zsh)"
