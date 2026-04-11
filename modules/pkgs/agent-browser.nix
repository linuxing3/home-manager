{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  patchelf,
  zlib,
}: let
  version = "0.25.3";
  src = fetchurl {
    url = "https://registry.npmjs.org/agent-browser/-/agent-browser-${version}.tgz";
    hash = "sha256-nImOug/P/8Mj9WDvZrsaArPQewcq7YI41LbGxGpByNs=";
  };
  platformBin =
    if stdenv.hostPlatform.system == "aarch64-linux"
    then "agent-browser-linux-arm64"
    else if stdenv.hostPlatform.system == "x86_64-linux"
    then "agent-browser-linux-x64"
    else throw "agent-browser: unsupported system ${stdenv.hostPlatform.system}";
  inherit (stdenv.cc.bintools) dynamicLinker;
  runtimeLibPath = lib.makeLibraryPath [
    stdenv.cc.cc
    zlib
  ];
  engine = "lightpanda";
in
  stdenv.mkDerivation {
    pname = "agent-browser";
    inherit version src;

    nativeBuildInputs = [makeWrapper patchelf];

    dontBuild = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin $out/lib/agent-browser

      tar -xzf $src
      cp package/bin/${platformBin} $out/lib/agent-browser/agent-browser
      chmod +x $out/lib/agent-browser/agent-browser

      patchelf --set-interpreter ${dynamicLinker} $out/lib/agent-browser/agent-browser
      patchelf --set-rpath ${runtimeLibPath} $out/lib/agent-browser/agent-browser

      # The binary itself is already patched with the Nix dynamic linker and
      # rpath above. Do not export LD_LIBRARY_PATH from the wrapper: agent-browser
      # spawns system browsers, and leaking Nix libgcc into /opt browser builds
      # makes them fail against the host glibc before DevToolsActivePort appears.
      makeWrapper $out/lib/agent-browser/agent-browser $out/bin/agent-browser \
        --set-default AGENT_BROWSER_ENGINE ${engine}\
        --unset LD_LIBRARY_PATH \
        --set NIX_LD ${dynamicLinker} \
        --set NIX_LD_LIBRARY_PATH ${runtimeLibPath}

      runHook postInstall
    '';

    meta = with lib; {
      description = "Agent Browser CLI";
      homepage = "https://agent-browser.dev/";
      license = licenses.asl20;
      platforms = ["x86_64-linux" "aarch64-linux"];
      mainProgram = "agent-browser";
    };
  }
