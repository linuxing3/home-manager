{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_20,
}:
buildNpmPackage rec {
  pname = "open-design";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "nexu-io";
    repo = "open-design";
    rev = "bc2198103ae2131a836ce26fa0ad13fbd6550aaf";
    hash = "sha256-C3BV12FyM8bsxcT1Bj6J1othLkPTAsHuRTxNhBoWFmM=";
  };

  npmDepsHash = "sha256-UkxTZVpYUVpR9GJLHGpELxEVCCYzo/kJOYdIF7ZTh7E=";

  nativeBuildInputs = [ nodejs_20 ];

  postPatch = ''
    substituteInPlace daemon/server.js \
      --replace-fail "const ARTIFACTS_DIR = path.join(PROJECT_ROOT, '.od', 'artifacts');" "const ARTIFACTS_DIR = path.join(process.env.OD_DATA_DIR || path.join(os.homedir(), '.local', 'share', 'open-design'), '.od', 'artifacts');" \
      --replace-fail "const PROJECTS_DIR = path.join(PROJECT_ROOT, '.od', 'projects');" "const PROJECTS_DIR = path.join(process.env.OD_DATA_DIR || path.join(os.homedir(), '.local', 'share', 'open-design'), '.od', 'projects');" \
      --replace-fail "  const db = openDatabase(PROJECT_ROOT);" "  const db = openDatabase(process.env.OD_DATA_DIR || path.join(os.homedir(), '.local', 'share', 'open-design'));"
  '';

  postInstall = ''
    if [ -x "$out/bin/od" ]; then
      mv "$out/bin/od" "$out/bin/open-design"
      ln -s "$out/bin/open-design" "$out/bin/od"
    fi
  '';

  meta = with lib; {
    description = "Open-source local-first alternative to Claude Design";
    homepage = "https://github.com/nexu-io/open-design";
    license = licenses.asl20;
    platforms = platforms.unix;
    mainProgram = "od";
  };
}
