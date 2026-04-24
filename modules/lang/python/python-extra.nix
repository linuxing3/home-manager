{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.features.home;
in
{
  options.my.features.home.pythonExtra = lib.mkEnableOption "Enable extra Python toolchain module";

  config = lib.mkIf cfg.pythonExtra {
    # installing all packages
    home.packages = with pkgs; [
      uv
      aider-chat
      (python3.withPackages (
        p: with p; [
          ddgr
          buku
          pandas
          requests
          epc
          lxml
          pysocks
          pymupdf
          pygetwindow
          pyqtwebengine
          pyqt5
          pyqt5-sip
          markdown
          orgparse
          ipython
          jinja2
          ddgr
        ]
      ))
    ];
  };
}
