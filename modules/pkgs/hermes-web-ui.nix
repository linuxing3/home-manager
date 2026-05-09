{
lib,
buildNpmPackage,
fetchFromGitHub,
makeWrapper,
nodejs_24,
}:
buildNpmPackage rec {
  pname = "hermes-web-ui";
  version = "0.4.9";

  src = fetchFromGitHub {
    owner = "EKKOLearnAI";
    repo = "hermes-web-ui";
    rev = "5193dbc49e7585009b6cbacb8dbba4aa22ea417b";
    hash = "sha256-IsThE/V4mgsq99uNurx/ZsxRQh5UtcqAftxlRQgpkpI=";
  };

  npmDepsHash = "sha256-ixDbQoXhPIRX3hW+AnD1/eUQm3eqWOwY6ABZ70T+EwQ=";

  postPatch = ''
    cp ${./hermes-web-ui-package-lock.json} package-lock.json
  '';

  nativeBuildInputs = [ makeWrapper nodejs_24 ];

  postInstall = ''
    wrapProgram $out/bin/hermes-web-ui \
      --set-default NODE_OPTIONS "--disable-warning=ExperimentalWarning"
  '';

  meta = with lib; {
    description = "Web dashboard CLI for Hermes Agent";
    homepage = "https://github.com/EKKOLearnAI/hermes-web-ui";
    license = licenses.mit;
    platforms = platforms.unix;
    mainProgram = "hermes-web-ui";
  };
}
