{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  openssl,
  zlib,
  libgit2,
}:
rustPlatform.buildRustPackage rec {
  pname = "mcp-cli";
  version = "unstable-2026-04-20";

  src = fetchFromGitHub {
    owner = "madeye";
    repo = "mcp-cli";
    rev = "cdfca17a9672c1f98d554fe7eb7b3c7adf7b63ad";
    hash = "sha256-kU5f6yHE26jOoyi/MBMnhXSBhvxggW1vcRmPAx2cM0E=";
  };

  cargoHash = "sha256-ma165KaMp4vVNxM43vn/vYEYFhS/+prdxKzPNTg6li0=";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl zlib libgit2 ];

  doCheck = false;

  meta = with lib; {
    description = "Sidecar daemon and MCP bridge for faster AI-agent filesystem/code access";
    homepage = "https://github.com/madeye/mcp-cli";
    license = licenses.mit;
    mainProgram = "mcp-cli";
    platforms = platforms.linux ++ platforms.darwin;
  };
}
