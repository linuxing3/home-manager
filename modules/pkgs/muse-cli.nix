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
