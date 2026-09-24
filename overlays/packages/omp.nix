_final: prev: {
  omp = prev.callPackage (
    {
      lib,
      stdenv,
      fetchurl,
      autoPatchelfHook,
      makeBinaryWrapper,
      python3,
    }: let
      version = "18.2.9";
      sources = {
        aarch64-linux = {
          url = "https://github.com/can1357/oh-my-pi/releases/download/v${version}/omp-linux-arm64";
          hash = "sha256-xFXSZbqyJ9Je566MHhtaINKTVP+R0v5zHWEuFANHzS0=";
        };
        x86_64-linux = {
          url = "https://github.com/can1357/oh-my-pi/releases/download/v${version}/omp-linux-x64";
          hash = "sha256-fee+ZxvyfVoqFf/3kUkOMZ/txZ5esXWc6iBg4ULAhuw=";
        };
      };
      srcInfo =
        sources.${stdenv.hostPlatform.system}
          or (throw "omp: unsupported system ${stdenv.hostPlatform.system}");
      # dlopen'd addons (onnxruntime, sherpa, sharp, …) need libstdc++/libgcc;
      # omp injects OMP_NATIVE_LIBRARY_PATH into inference workers only.
      runtimeNativeLibraries =
        [stdenv.cc.cc.lib]
        ++ lib.optional (stdenv.cc.cc ? libgcc) stdenv.cc.cc.libgcc;
    in
      stdenv.mkDerivation {
        pname = "omp";
        inherit version;

        src = fetchurl srcInfo;
        dontUnpack = true;
        dontStrip = true;

        nativeBuildInputs = [
          autoPatchelfHook
          makeBinaryWrapper
          python3
        ];
        buildInputs = [stdenv.cc.cc.lib];

        installPhase = ''
          runHook preInstall
          install -Dm755 "$src" "$out/bin/omp"
          runHook postInstall
        '';

        # Force libstdc++ into the main process so dlopen'd addons resolve it
        # by soname. Growing .dynamic leaves DT_VERDEF stale on bun --compile
        # ELFs (oh-my-pi #9881); repair in preInstallCheck after every
        # patchelf/autoPatchelf pass (hooks may run after postFixup).
        postFixup = ''
          patchelf --add-needed libstdc++.so.6 "$out/bin/omp"
          wrapProgram "$out/bin/omp" \
            --set-default OMP_NATIVE_LIBRARY_PATH "${lib.makeLibraryPath runtimeNativeLibraries}"
        '';

        doInstallCheck = true;
        preInstallCheck = ''
          python3 ${./omp-fix-dt-verdef.py} "$out/bin/.omp-wrapped"
        '';
        installCheckPhase = ''
          runHook preInstallCheck
          smokeOutput="$(HOME="$TMPDIR" "$out/bin/omp" --smoke-test)"
          grep -q "smoke-test: ok" <<<"$smokeOutput"
          patchelf --print-needed "$out/bin/.omp-wrapped" | grep -q '^libstdc++\.so\.6$'
          runHook postInstallCheck
        '';

        meta = {
          description = "Terminal-based coding agent with multi-model support (GitHub release binary)";
          homepage = "https://omp.sh";
          changelog = "https://github.com/can1357/oh-my-pi/releases/tag/v${version}";
          license = lib.licenses.mit;
          mainProgram = "omp";
          platforms = builtins.attrNames sources;
          sourceProvenance = [lib.sourceTypes.binaryNativeCode];
        };
      }
  ) {};
}
