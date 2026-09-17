{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.features.home.nnn;
  nnnSrc = pkgs.nnn.src;
  previewTabbed = pkgs.runCommand "nnn-preview-tabbed" {} ''
    substitute ${nnnSrc}/plugins/preview-tabbed "$out" \
      --replace-fail 'if type zathura >/dev/null 2>&1 ; then' 'if [ -x ${lib.getExe pkgs.zathura} ] ; then' \
      --replace-fail 'zathura -e "$XID" "$FILE" &' '${lib.getExe pkgs.zathura} -e "$XID" "$FILE" &'
    chmod +x "$out"
  '';
  nuke = pkgs.runCommand "nnn-nuke" {} ''
    substitute ${nnnSrc}/plugins/nuke "$out" \
      --replace-fail '        ## PDF' '        ## Microsoft Office
        docx)
            ${lib.getExe pkgs.doxx} --export ansi -- "$FPATH" | eval "$PAGER"
            exit 0;;
        xlsx|xls|xlsm|ods)
            ${lib.getExe pkgs.xleak} "$FPATH" | eval "$PAGER"
            exit 0;;

        ## PDF'
    chmod +x "$out"
  '';
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
          source =
            if name == "preview-tabbed"
            then previewTabbed
            else if name == "nuke"
            then nuke
            else "${nnnSrc}/plugins/${name}";
          executable = true;
        };
      })
      cfg.plugins
    );
  };
}
