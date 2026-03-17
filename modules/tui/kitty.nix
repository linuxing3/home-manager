{ pkgs, ... }:

{
  home.packages = with pkgs; [
    kitty.terminfo
    (writeShellScriptBin "kitty" ''
      if [ -x /usr/bin/kitty ]; then
        exec /usr/bin/kitty "$@"
      fi

      exec ${kitty}/bin/kitty "$@"
    '')
  ];

  home.file = {
    ".config/kitty" = {
      source = ../../configs/kitty;
      recursive = true;
    };
  };

}
