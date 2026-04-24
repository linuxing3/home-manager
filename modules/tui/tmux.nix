{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.features.home;
  fzfLinksDir = "${config.home.homeDirectory}/.local/share/tmux-fzf-links";
in
{
  options.my.features.home.tmux = lib.mkEnableOption "Enable tmux module";

  config = lib.mkIf cfg.tmux {
    home.packages = with pkgs; [
      bun
      fzf
      git
      (writeShellScriptBin "nfx" ''
        if [ -n "$TMUX" ]; then
            nnn -a $@
        else
            tmux -u new-session nnn -a $@
        fi
        exit 0
      '')
      (writeShellScriptBin "tile" ''
        PID=$(pidof $1)
        if [ -z "$PID" ]; then
            tmux new-session -d -s workspace;
            tmux new-window -t workspace -n $1 "$*" ;
        fi
        tmux attach-session -d -t workspace;
        tmux select-window -t $1 ;
        exit 0
      '')
      (writeShellScriptBin "tmux_split_curdir" ''
        cwd=
        cc=$(tmux display -p '#{pane_current_command}')
        if [ $cc == "tmux" ] ; then
           cwd=$(lsof -w -c tmux | grep cwd | tail -n 1 | awk '{print $9}')
        else
           cwd=$(tmux display -p '#{pane_current_path}')
        fi
        tmux command-prompt "split-window -h -c \"$cwd\" -l 80% \"exec %%\""
      '')
    ];

    programs.tmux = {
      enable = true;
      baseIndex = 1;
      clock24 = true;
      escapeTime = 0;
      focusEvents = false;
      historyLimit = 2000;
      keyMode = "vi";
      mouse = true;
      prefix = "C-b";
      shell = "${pkgs.zsh}/bin/zsh";
      terminal = "xterm-256color";
      plugins = with pkgs.tmuxPlugins; [
        jump
        cpu
        sidebar
        logging
        resurrect
        fzf-tmux-url
        prefix-highlight
        tmux-floax
        tmux-fzf
        tmux-thumbs
        tmux-which-key
        gruvbox
        # tmux-powerline
        # catppuccin
        # nord
        # rose-pine
        # onedark-theme
        # tokyo-night-tmux
      ];
      extraConfig = ''
        set -g allow-passthrough on
        set -ga update-environment TERM
        set -ga update-environment TERM_PROGRAM
        set-option -g default-command "exec ${pkgs.zsh}/bin/zsh"
        set-option -g lock-after-time 1800

        # DESIGN TWEAKS
        set -g visual-activity off
        set -g visual-bell off
        set -g visual-silence off
        setw -g monitor-activity off
        set -g bell-action none

        # BINDING TWEAKS
        bind-key b set-option status
        bind-key -n M-r source-file ~/.config/tmux/tmux.conf \; display-message "source-file done"
        bind-key Space command-prompt "new-window -n %1 \"exec %1\""
        bind-key / command-prompt "split-window \"exec man %%\""
        bind-key S command-prompt "new-window -n %1 \"ssh %1\""
        bind -n M-m run-shell "tmux_split_curdir"
        bind -n M-n split-window -h \; select-layout tiled
        bind -n M-o next-layout
        bind -n M-g select-pane -m
        bind -n M-y run 'tmux swap-pane -s \{marked\} && tmux select-pane -M'
        bind-key '|' split-window -h
        bind-key '-' split-window
        bind-key -n M-| split-window -h
        bind-key -n M-_ split-window
        bind-key -n M-H previous-window
        bind-key -n M-L next-window
        bind-key -n M-w kill-pane
        bind-key -n C-h select-pane -L
        bind-key -n C-l select-pane -R
        bind-key -n C-k select-pane -U
        bind-key -n C-j select-pane -D
        bind-key -n M-f resize-pane -Z

        # COPY TWEAKS
        bind-key -n M-[ copy-mode
        bind-key -T copy-mode-vi v send-keys -X begin-selection
        bind-key -T copy-mode-vi y send-keys -X copy-selection
        bind-key -T copy-mode-vi x send-keys -X select-line
        bind-key -n M-] paste-buffer -p

        # === tmux-fzf-links ===
        set-option -g @fzf-links-editor-open-cmd "tmux new-window -n 'hx' hx +%line '%file'"
        set-option -g @fzf-links-browser-open-cmd "/usr/bin/brave-browser '%url'"
        set-option -g @fzf-links-fzf-path "${pkgs.fzf}/bin/fzf"
        set-option -g @fzf-links-fzf-display-options "-w 100% --maxnum-displayed 20 --multi --track --no-preview"
        set-option -g @fzf-links-log-filename "~/.local/state/tmux-fzf-links.log"
        set-option -g @fzf-links-python "python3"
        set-option -g @fzf-links-use-colors on
        set-option -g @fzf-links-hide-bottom-bar off

        # FzfLinks (local checkout mode per upstream docs)
        run-shell "${fzfLinksDir}"/fzf-links.tmux

        # Optional local overrides
        if-shell "[ -f ~/.config/tmux/private.conf ]" "source-file ~/.config/tmux/private.conf"
      '';
    };

    home.activation.fzfLinksCheckout = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      target="${fzfLinksDir}"
      if [ ! -d "$target/.git" ]; then
        $DRY_RUN_CMD mkdir -p "$(dirname "$target")"
        if [ -z "$DRY_RUN_CMD" ]; then
          ${pkgs.git}/bin/git clone --depth=1 https://github.com/alberti42/tmux-fzf-links.git "$target"
        fi
      fi
    '';
  };
}
