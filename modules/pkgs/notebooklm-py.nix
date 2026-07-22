{
  lib,
  fetchPypi,
  python3Packages,
}:
python3Packages.buildPythonApplication rec {
  pname = "notebooklm-py";
  version = "0.3.4";
  pyproject = true;

  src = fetchPypi {
    pname = "notebooklm_py";
    inherit version;
    hash = "sha256-3HL4mx60wO+62GQaDsg9ouYxxakm4CmpOiWLADK1A8Q=";
  };

  build-system = [
    python3Packages.hatchling
    python3Packages."hatch-fancy-pypi-readme"
  ];

  dependencies = with python3Packages; [
    click
    httpx
    rich
    playwright
  ];

  pythonImportsCheck = [ "notebooklm" ];

  meta = with lib; {
    description = "Unofficial Python library for automating Google NotebookLM";
    homepage = "https://github.com/teng-lin/notebooklm-py";
    changelog = "https://github.com/teng-lin/notebooklm-py/blob/main/CHANGELOG.md";
    license = licenses.mit;
    mainProgram = "notebooklm";
    platforms = platforms.unix;
  };
}
