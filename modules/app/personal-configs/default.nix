{
  config,
  lib,
  pkgs,
  ...
}: let
  homeDir = config.home.homeDirectory;
  configHome = config.xdg.configHome;
  files = ./files;
  cloudflaredDefaults = pkgs.writeText "cloudflared-defaults.json" (builtins.toJSON {
    ingress = [
      {
        hostname = "efwmcsyle.ccwu.cc";
        service = "ssh://127.0.0.1:22";
      }
      {service = "http_status:404";}
    ];
  });
in {
  programs.atuin.settings = {
    enter_accept = true;
    search_mode = "daemon-fuzzy";
    sync.records = true;
    daemon = {
      enabled = true;
      autostart = true;
    };
    dotfiles.enable = true;
  };

  xdg.configFile = {
    "glow/glow.yml".source = files/glow/glow.yml;
    "television/config.toml".source = files/television/config.toml;
    "zellij/config.kdl".source = files/zellij/config.kdl;
    "smplayer/hdpi.ini".text = ''
      [hdpisupport]
      auto_scale=true
      enabled=false
      pixel_ratio=2
      scale_factor=1
    '';
  };

  home.activation.mergeDesktopConfigs = lib.hm.dag.entryAfter ["writeBoundary"] ''
    set -eu

    preserve_once() {
      source=$1
      if [[ -f "$source" && ! -e "$source.hm-bak" ]]; then
        ${pkgs.coreutils}/bin/cp --preserve=mode,timestamps -- "$source" "$source.hm-bak"
      fi
    }

    cloudflared_config=${lib.escapeShellArg "${homeDir}/.cloudflared/config.yml"}
    if [[ -f "$cloudflared_config" ]]; then
      preserve_once "$cloudflared_config"
      ${pkgs.yq}/bin/yq --yaml-output --in-place --slurpfile defaults ${cloudflaredDefaults} \
        '. * $defaults[0]' "$cloudflared_config"
      ${pkgs.coreutils}/bin/chmod --reference="$cloudflared_config.hm-bak" "$cloudflared_config"
    fi

    smplayer=${lib.escapeShellArg "${configHome}/smplayer/smplayer.ini"}
    if [[ -f "$smplayer" ]]; then
      preserve_once "$smplayer"
      ${pkgs.python3}/bin/python3 ${./merge-smplayer.py} "$smplayer"
    fi

    gcloud_config=${lib.escapeShellArg "${configHome}/gcloud/configurations/config_default"}
    if [[ -f "$gcloud_config" ]]; then
      preserve_once "$gcloud_config"
      ${pkgs.python3}/bin/python3 ${./merge-gcloud.py} "$gcloud_config"
    fi
  '';
}
