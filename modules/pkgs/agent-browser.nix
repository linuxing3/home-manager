{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  patchelf,
  zlib,
}:

let
  version = "0.25.3";
  src = fetchurl {
    url = "https://registry.npmjs.org/agent-browser/-/agent-browser-${version}.tgz";
    hash = "sha256-nImOug/P/8Mj9WDvZrsaArPQewcq7YI41LbGxGpByNs=";
  };
  platformBin =
    if stdenv.hostPlatform.system == "aarch64-linux" then
      "agent-browser-linux-arm64"
    else if stdenv.hostPlatform.system == "x86_64-linux" then
      "agent-browser-linux-x64"
    else
      throw "agent-browser: unsupported system ${stdenv.hostPlatform.system}";
  dynamicLinker = stdenv.cc.bintools.dynamicLinker;
  runtimeLibPath = lib.makeLibraryPath [
    stdenv.cc.cc
    zlib
  ];
in
stdenv.mkDerivation {
  pname = "agent-browser";
  inherit version src;

  nativeBuildInputs = [ makeWrapper patchelf ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/lib/agent-browser

    tar -xzf $src
    cp package/bin/${platformBin} $out/lib/agent-browser/agent-browser
    chmod +x $out/lib/agent-browser/agent-browser

    patchelf --set-interpreter ${dynamicLinker} $out/lib/agent-browser/agent-browser
    patchelf --set-rpath ${runtimeLibPath} $out/lib/agent-browser/agent-browser

    makeWrapper $out/lib/agent-browser/agent-browser $out/bin/agent-browser \
      --set LD_LIBRARY_PATH ${runtimeLibPath} \
      --set NIX_LD ${dynamicLinker} \
      --set NIX_LD_LIBRARY_PATH ${runtimeLibPath}

    runHook postInstall
  '';

  meta = with lib; {
    description = "Agent Browser CLI";
    homepage = "https://agent-browser.dev/";
    license = licenses.asl20;
    platforms = [ "x86_64-linux" "aarch64-linux" ];
    mainProgram = "agent-browser";
  };
}
