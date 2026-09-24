_final: prev: {
  pi = prev.callPackage (
    {
      lib,
      stdenv,
      fetchurl,
      autoPatchelfHook,
      makeBinaryWrapper,
      python3,
      fd,
      ripgrep,
      libxcb,
    }: let
      version = "0.87.1";
      sources = {
        aarch64-linux = {
          url = "https://github.com/earendil-works/pi/releases/download/v${version}/pi-linux-arm64.tar.gz";
          hash = "sha256-NktKn4SRRQsnpIV9Tjx4Dbr2lnkIIcF2qHPoYMu8O4k=";
        };
        x86_64-linux = {
          url = "https://github.com/earendil-works/pi/releases/download/v${version}/pi-linux-x64.tar.gz";
          hash = "sha256-gNeN1i1QBJoAa5gdmUxhJVvMEOcwsMJ41OoKdVkJdkw=";
        };
      };
      srcInfo =
        sources.${stdenv.hostPlatform.system}
          or (throw "pi: unsupported system ${stdenv.hostPlatform.system}");
      nativeTarget =
        if stdenv.hostPlatform.isAarch64
        then "linux-arm64"
        else "linux-x64";
    in
      stdenv.mkDerivation {
        pname = "pi";
        inherit version;

        src = fetchurl srcInfo;
        sourceRoot = "pi";
        dontStrip = true;

        nativeBuildInputs = [
          autoPatchelfHook
          makeBinaryWrapper
          python3
        ];
        # linux-platform-x11.node needs libxcb; the bun ELF needs glibc/libstdc++.
        buildInputs = [
          stdenv.cc.cc.lib
          libxcb
        ];

        installPhase = ''
          runHook preInstall
          mkdir -p "$out/libexec/pi" "$out/bin"
          cp -a . "$out/libexec/pi/"
          chmod +x "$out/libexec/pi/pi"
          runHook postInstall
        '';

        # Keep the ELF at libexec/pi/pi: the UOS loader shim execs that path
        # directly. Growing .dynamic via autoPatchelf leaves DT_VERDEF stale on
        # bun --compile ELFs (same class of bug as oh-my-pi #9881).
        postFixup = ''
          makeWrapper "$out/libexec/pi/pi" "$out/bin/pi" \
            --prefix PATH : ${lib.makeBinPath [fd ripgrep]} \
            --set PI_PACKAGE_DIR "$out/libexec/pi" \
            --set PI_SKIP_VERSION_CHECK 1 \
            --set PI_TELEMETRY 0
        '';

        doInstallCheck = true;
        preInstallCheck = ''
          python3 ${./omp-fix-dt-verdef.py} "$out/libexec/pi/pi"
        '';
        installCheckPhase = ''
          runHook preInstallCheck
          "$out/bin/pi" --version | grep -F "${version}"
          test -f "$out/libexec/pi/native/linux/prebuilds/${nativeTarget}/linux-platform-x11.node"
          runHook postInstallCheck
        '';

        meta = {
          description = "Terminal coding agent with multi-model support (GitHub release binary)";
          homepage = "https://github.com/earendil-works/pi";
          changelog = "https://github.com/earendil-works/pi/releases/tag/v${version}";
          license = lib.licenses.mit;
          mainProgram = "pi";
          platforms = builtins.attrNames sources;
          sourceProvenance = [lib.sourceTypes.binaryNativeCode];
        };
      }
  ) {};
}
