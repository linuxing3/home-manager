{
  lib,
  fetchPypi,
  python3Packages,
}:
python3Packages.buildPythonApplication rec {
  pname = "muse-cli";
  version = "0.3.1";
  pyproject = true;

  src = fetchPypi {
    pname = "muse_cli";
    inherit version;
    hash = "sha256-QPL0vUCFvIe+xsz//ksz07o3QAp7p2mMqL4Q8hAuizA=";
  };

  # agent-browser 0.25 lists tabs by `index` only; upstream expects `id`/`tabId`
  # and otherwise reports "no muse.ai tab open".
  postPatch = ''
    substituteInPlace src/muse_cli/cli.py \
      --replace-fail 'and (t.get("id") or t.get("tabId"))]' \
                     'and _tab_ref(t) is not None]' \
      --replace-fail 'tab_id = (muse_tabs[0].get("id") or muse_tabs[0].get("tabId")' \
                     'tab_id = (_tab_ref(muse_tabs[0])' \
      --replace-fail 'def _browser_cookies():' \
                     'def _tab_ref(t):
        for key in ("id", "tabId", "targetId"):
            if t.get(key):
                return str(t[key])
        if isinstance(t.get("index"), int):
            return str(t["index"])
        return None


    def _browser_cookies():'
  '';

  build-system = [python3Packages.hatchling];

  dependencies = with python3Packages; [
    curl-cffi
    noiseprotocol
    protobuf
  ];

  # Upgrades come from Nix, not `muse-cli update`.
  makeWrapperArgs = ["--set-default" "MUSE_NO_UPDATE_CHECK" "1"];

  pythonImportsCheck = ["muse_cli"];

  meta = with lib; {
    description = "CLI for your personal muse.ai AI agent";
    homepage = "https://github.com/nikships/muse-cli";
    changelog = "https://github.com/nikships/muse-cli/releases/tag/v${version}";
    license = licenses.mit;
    mainProgram = "muse-cli";
    platforms = platforms.unix;
  };
}
