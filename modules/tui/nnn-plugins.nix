{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.features.home.nnn;
  nnnSrc = pkgs.nnn.src;
in {
  options.my.features.home.nnn.plugins = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [
      "nuke"
      "preview-tabbed"
      "imgview"
      "launch"
      "fzcd"
      "gitroot"
      "gpge"
      "gpgd"
      "gpgs"
      "gpgv"
    ];
    description = "jarun/nnn plugin scripts installed under ~/.config/nnn/plugins.";
  };

  config = {
    xdg.configFile = lib.listToAttrs (
      map (name: {
        name = "nnn/plugins/${name}";
        value = {
          source = "${nnnSrc}/plugins/${name}";
          executable = true;
        };
      })
      cfg.plugins
    );
  };
}
