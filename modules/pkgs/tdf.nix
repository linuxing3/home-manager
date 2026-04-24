{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  clang,
  fontconfig,
  mupdf,
}:
rustPlatform.buildRustPackage rec {
  pname = "tdf";
  version = "0.5.0";

  src = fetchFromGitHub {
    owner = "itsjunetime";
    repo = "tdf";
    rev = "v${version}";
    hash = "sha256-KrjSIpFXK4zEJYqkVgcqbH0DNNCWVst7j5NZ+e8/m5Q=";
  };

  cargoHash = "sha256-lGbsb3hlFen0tXBVLbm8+CE5dddv6Ner4YSAvAd3/ug=";

  nativeBuildInputs = [
    pkg-config
    clang
    rustPlatform.bindgenHook
  ];

  buildInputs = [
    fontconfig
    mupdf
  ];

  meta = with lib; {
    description = "A terminal-based PDF viewer";
    homepage = "https://github.com/itsjunetime/tdf";
    license = licenses.agpl3Only;
    mainProgram = "tdf";
    platforms = platforms.unix;
  };
}
