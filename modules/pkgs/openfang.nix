{
  lib,
  stdenv,
  stdenvNoCC,
  fetchurl,
  patchelf,
  zlib,
  openssl,
  xz,
  bzip2,
}:
let
  version = "0.6.0";
  target =
    if stdenv.hostPlatform.system == "x86_64-linux"
    then "x86_64-unknown-linux-gnu"
    else if stdenv.hostPlatform.system == "aarch64-linux"
    then "aarch64-unknown-linux-gnu"
    else throw "openfang: unsupported system ${stdenv.hostPlatform.system}";

  hashes = {
    x86_64-unknown-linux-gnu = "sha256-Jjiu9JY/ynhnqgAwR1+Fo+5Zq3zr10RTJAQD6E3i+Gc=";
    aarch64-unknown-linux-gnu = "sha256-IYpYhaFZmy4tlOno7RRV4KWYpmvEh0rD9ljgQ8o0wB4=";
  };

  inherit (stdenv.cc.bintools) dynamicLinker;
  runtimeLibPath = lib.makeLibraryPath [
    stdenv.cc.cc
    zlib
    openssl
    xz
    bzip2
  ];
in
stdenvNoCC.mkDerivation {
  pname = "openfang";
  inherit version;

  src = fetchurl {
    url = "https://github.com/RightNow-AI/openfang/releases/download/v${version}/openfang-${target}.tar.gz";
    hash = hashes.${target};
  };

  nativeBuildInputs = [ patchelf ];

  dontBuild = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/openfang $out/bin

    tar -xzf $src
    bin=$(find . -type f -name openfang | head -n1)
    if [ -z "$bin" ]; then
      echo "openfang binary not found in archive" >&2
      exit 1
    fi

    install -m755 "$bin" $out/lib/openfang/openfang

    if patchelf --print-interpreter $out/lib/openfang/openfang >/dev/null 2>&1; then
      patchelf --set-interpreter ${dynamicLinker} $out/lib/openfang/openfang
      patchelf --set-rpath ${runtimeLibPath} $out/lib/openfang/openfang
    fi

    ln -s $out/lib/openfang/openfang $out/bin/openfang

    runHook postInstall
  '';

  meta = with lib; {
    description = "Open-source command line utility for comprehensive MCP server and client management";
    homepage = "https://openfang.sh";
    license = licenses.mit;
    platforms = [ "x86_64-linux" "aarch64-linux" ];
    mainProgram = "openfang";
  };
}
