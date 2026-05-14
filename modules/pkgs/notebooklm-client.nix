{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_20,
}:
buildNpmPackage rec {
  pname = "notebooklm-client";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "icebear0828";
    repo = "notebooklm-client";
    rev = "f70aaa8db496b3976927c1d135fe8509f7a59acc";
    hash = "sha256-Jfc2dd6R9QZVyBvNTICY5NOEDpUMOZXQZea+LNs5zII=";
  };

  npmDepsHash = "sha256-CCl3gfxTtDgfaHMWRgmMdpamC4lxKKIPSAFLyF+SFc8=";

  nativeBuildInputs = [ nodejs_20 ];

  postInstall = ''
    if [ -x "$out/bin/notebooklm" ]; then
      mv "$out/bin/notebooklm" "$out/bin/notebooklm-client"
    fi
  '';

  meta = with lib; {
    description = "Standalone CLI for Google NotebookLM";
    homepage = "https://github.com/icebear0828/notebooklm-client";
    license = licenses.mit;
    platforms = platforms.unix;
    mainProgram = "notebooklm-client";
  };
}
