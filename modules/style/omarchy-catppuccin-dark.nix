{
  config,
  lib,
  pkgs,
  ...
}: let
  revision = "54b98a5c7302783298df05238ab55f312ec327ea";
  fetchThemeFile = file: hash:
    pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/Luquatic/omarchy-catppuccin-dark/${revision}/${file}";
      inherit hash;
    };
  starshipConfig = fetchThemeFile "starship.toml" "sha256-FKRF8FUY3UeaOwMpgkK2FiQaAfPwFLfp6vPkiuDrc1s=";
  btopTheme = fetchThemeFile "btop.theme" "sha256-nvPImW3Nw3rIB8on/ldQ9Nhx3Ns8A46vuIpCz0G8/Ys=";
  kittyTheme = fetchThemeFile "kitty.conf" "sha256-BruzWXKJiofPO7KBFvsL51hinJv8TWIHuAQDe3Zi1r0=";
in {
  imports = [./stylix.nix];

  stylix = {
    icons = {
      enable = true;
      package = pkgs.yaru-theme;
      dark = "Yaru-purple";
      light = "Yaru-purple";
    };
    opacity = {
      applications = 1.0;
      desktop = 0.8;
      popups = 0.25;
      terminal = 0.4;
    };
    targets.kitty.enable = lib.mkForce false;
  };

  home.sessionVariables.STARSHIP_CONFIG = lib.mkForce starshipConfig;

  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };

  programs.kitty = {
    enable = true;
    extraConfig = ''
      include ${kittyTheme}

      # Runtime theme file updated by theme-switch
      include ~/.local/state/kitty-theme.conf

      # Enable remote control for live theme-switching
      allow_remote_control yes
      listen_on unix:/tmp/kitty-sock-$PPID
    '';
  };

  programs.fzf.defaultOptions = lib.mkForce [
    "--color=fg:#cdd6f4,fg+:#cdd6f4,bg:#010101,bg+:#313244"
    "--color=hl:#f5c2e7,hl+:#f5c2e7,info:#89b4fa,marker:#a6e3a1"
    "--color=prompt:#89b4fa,spinner:#94e2d5,pointer:#f5c2e7,header:#b4befe"
    "--color=border:#45475a,label:#cdd6f4,query:#cdd6f4"
    "--border='rounded' --border-label='' --preview-window='border-rounded' --prompt='> '"
    "--marker='>' --pointer='>' --separator='─' --scrollbar='│'"
    "--info='right'"
  ];

  xdg.configFile = {
    "btop/themes/omarchy-catppuccin-dark.theme".source = btopTheme;
    "gtk-3.0/gtk.css".force = true;
    "gtk-3.0/settings.ini".force = true;
    "gtk-4.0/gtk.css".force = true;
    "gtk-4.0/settings.ini".force = true;
  };

  home.activation.applyOmarchyAppThemes = lib.hm.dag.entryAfter ["writeBoundary"] ''
    btop_config=${lib.escapeShellArg "${config.xdg.configHome}/btop/btop.conf"}
    helix_config=${lib.escapeShellArg "${config.xdg.configHome}/helix/config.toml"}

    $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "$(dirname "$btop_config")" "$(dirname "$helix_config")"

    if [[ -f "$btop_config" ]]; then
      $DRY_RUN_CMD ${pkgs.gnused}/bin/sed -i \
        -e 's/^color_theme = .*/color_theme = "omarchy-catppuccin-dark"/' \
        -e 's/^theme_background = .*/theme_background = true/' \
        "$btop_config"
    elif [[ -z "$DRY_RUN_CMD" ]]; then
      printf '%s\n' \
        'color_theme = "omarchy-catppuccin-dark"' \
        'theme_background = true' >"$btop_config"
    fi

    if [[ -f "$helix_config" ]]; then
      if ${pkgs.gnugrep}/bin/grep -q '^theme = ' "$helix_config"; then
        $DRY_RUN_CMD ${pkgs.gnused}/bin/sed -i \
          's/^theme = .*/theme = "catppuccin_mocha"/' "$helix_config"
      elif [[ -z "$DRY_RUN_CMD" ]]; then
        printf '%s\n' 'theme = "catppuccin_mocha"' "$(cat "$helix_config")" >"$helix_config"
      fi
    elif [[ -z "$DRY_RUN_CMD" ]]; then
      printf '%s\n' 'theme = "catppuccin_mocha"' >"$helix_config"
    fi
  '';
}
