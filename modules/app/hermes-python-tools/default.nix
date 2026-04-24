{
  config,
  lib,
  pkgs,
  ...
}: let
  venvDir = "/sources/hermes-pytools/.venv";
  configHome =
    if lib.hasPrefix "/" config.xdg.configHome
    then config.xdg.configHome
    else "${config.home.homeDirectory}/${config.xdg.configHome}";
  requirementsFile = "${configHome}/hermes-python-tools/requirements.txt";
in {
  home.packages = [
    pkgs.uv

    (pkgs.writeShellScriptBin "hermes-pytools-python" ''
      unset VIRTUAL_ENV PYTHONHOME PYTHONPATH
      export PYTHONSAFEPATH=1
      export LD_LIBRARY_PATH="${pkgs.stdenv.cc.cc.lib}/lib:${pkgs.zlib}/lib:$LD_LIBRARY_PATH"
      exec "${venvDir}/bin/python" "$@"
    '')

    (pkgs.writeShellScriptBin "marker_single" ''
      unset VIRTUAL_ENV PYTHONHOME PYTHONPATH
      export PYTHONSAFEPATH=1
      export LD_LIBRARY_PATH="${pkgs.stdenv.cc.cc.lib}/lib:${pkgs.zlib}/lib:$LD_LIBRARY_PATH"
      exec "${venvDir}/bin/marker_single" "$@"
    '')
  ];

  xdg.configFile."hermes-python-tools/requirements.txt".text = ''
    crawl4ai==0.8.6
    scrapling==0.2.99
    camoufox==0.4.11
    marker-pdf
    tavily-python==0.7.23
  '';

  home.activation.hermesPythonToolsBootstrap = lib.hm.dag.entryAfter ["linkGeneration"] ''
    export PATH="${pkgs.uv}/bin:${pkgs.python3}/bin:$PATH"
    unset VIRTUAL_ENV PYTHONHOME PYTHONPATH
    VENV='${venvDir}'
    REQ='${requirementsFile}'

    mkdir -p "$(dirname "$VENV")"

    if [ ! -x "$VENV/bin/python" ]; then
      run ${pkgs.uv}/bin/uv venv --python '${pkgs.python3}/bin/python3' "$VENV"
    fi

    run ${pkgs.uv}/bin/uv pip install --python "$VENV/bin/python" --upgrade pip
    run ${pkgs.uv}/bin/uv pip install --python "$VENV/bin/python" -r "$REQ"
  '';
}
