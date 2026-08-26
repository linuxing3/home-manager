{
  config,
  pkgs,
  ...
}: let
  myCbxScript = ''
    #!/bin/sh

    # this lets my copy and paste images and/or plaintext of files directly out of ranger
    if [ "$#" -le "2" ]; then
      if [ "$1" = "copy" -o "$1" = "cut" ]; then
        xclip -selection clipboard -t image/png -i $2;
      fi
    fi
  '';
in {
  imports = [../../pkgs/ranger.nix];

  home.packages = with pkgs; [
    ranger
    ripdrag
    highlight
    (pkgs.writeScriptBin "cbx" myCbxScript)
  ];
  xdg.mimeApps.associations.added = {
    "inode/directory" = "ranger.desktop";
  };
  home.file.".config/ranger/rc.conf".source = ./rc.conf;
  home.file.".config/ranger/rifle.conf".source = ./rifle.conf;
  home.file.".config/ranger/scope.sh" = {
    source = ./scope.sh;
    executable = true;
  };
  home.file.".config/ranger/commands.py" = {
    source = ./commands.py;
    executable = true;
  };
  home.file.".config/ranger/commands_full.py" = {
    source = ./commands_full.py;
    executable = true;
  };
  home.file.".config/ranger/colorschemes/hail.py" = {
    source = ./colorschemes/hail.py;
    executable = true;
  };
}
