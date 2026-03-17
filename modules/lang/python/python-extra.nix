{
  pkgs,
  ...
}:
{

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

}
