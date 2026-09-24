{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  patchelf,
}: let
  version = "0.4.1";
  artifact =
    if stdenv.hostPlatform.system == "aarch64-linux"
    then {
      name = "linux-arm64";
      hash = "sha256-RWxymzvY262REaxzpTEGnMv0WBe1HQNBC25tEifvxx8=";
    }
    else if stdenv.hostPlatform.system == "x86_64-linux"
    then {
      name = "linux-x64";
      hash = "sha256-7JVfm9g54GSVPP9qakX/xaT2LsFk8yLLo54IyQ3CeRA=";
    }
    else throw "webcodex: unsupported system ${stdenv.hostPlatform.system}";
  inherit (stdenv.cc.bintools) dynamicLinker;
  runtimeLibPath = lib.makeLibraryPath [stdenv.cc.cc];
in
  stdenv.mkDerivation {
    pname = "webcodex";
    inherit version;

    src = fetchurl {
      url = "https://github.com/yyjeqhc/webcodex/releases/download/v${version}/webcodex-v${version}-${artifact.name}.tar.gz";
      inherit (artifact) hash;
    };

    nativeBuildInputs = [makeWrapper patchelf];

    sourceRoot = ".";
    dontBuild = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/lib/webcodex $out/bin
      for bin in webcodex webcodex-server webcodex-runner; do
        install -Dm755 "$bin" "$out/lib/webcodex/$bin"
        patchelf --set-interpreter ${dynamicLinker} "$out/lib/webcodex/$bin"
        patchelf --set-rpath ${runtimeLibPath} "$out/lib/webcodex/$bin"
        makeWrapper "$out/lib/webcodex/$bin" "$out/bin/$bin"
      done

      runHook postInstall
    '';

    meta = with lib; {
      description = "Connect ChatGPT/Claude to local repos via WebCodex Server + Runner";
      homepage = "https://github.com/yyjeqhc/webcodex";
      license = licenses.asl20;
      platforms = ["x86_64-linux" "aarch64-linux"];
      mainProgram = "webcodex";
    };
  }
