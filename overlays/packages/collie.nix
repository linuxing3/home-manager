_final: prev: {
  collie = prev.callPackage (
    {
      lib,
      stdenv,
      fetchurl,
      autoPatchelfHook,
      makeBinaryWrapper,
      python3,
    }: let
      version = "1.11.1";
      sources = {
        aarch64-linux = {
          url = "https://github.com/AltanS/collie/releases/download/v${version}/collie-${version}-linux-arm64.tar.gz";
          hash = "sha256-KxXhnQNhMZoD1wPJ+zw2QnC2L/fBgUxSsTx9CVe3SVQ=";
        };
        x86_64-linux = {
          url = "https://github.com/AltanS/collie/releases/download/v${version}/collie-${version}-linux-x64.tar.gz";
          hash = "sha256-EQyB7MoOEz4HVe39dPWqFzoT7wzbYiz1aRh5/9m9BfI=";
        };
      };
      srcInfo =
        sources.${stdenv.hostPlatform.system}
          or (throw "collie: unsupported system ${stdenv.hostPlatform.system}");
    in
      stdenv.mkDerivation {
        pname = "collie";
        inherit version;

        src = fetchurl srcInfo;
        # tarball root is collie-<ver>-linux-<arch>/
        sourceRoot = "collie-${version}-linux-${
          if stdenv.hostPlatform.isAarch64
          then "arm64"
          else "x64"
        }";
        dontStrip = true;

        nativeBuildInputs = [
          autoPatchelfHook
          makeBinaryWrapper
          python3
        ];
        buildInputs = [stdenv.cc.cc.lib];

        installPhase = ''
          runHook preInstall
          # Keep release layout so the bun binary can find ../web/dist.
          mkdir -p "$out/lib/collie" "$out/bin"
          cp -a . "$out/lib/collie/"
          chmod +x "$out/lib/collie/bin/collie"
          runHook postInstall
        '';

        # Leave the ELF in place so relative ../web/dist resolves; wrap only PATH entry.
        postFixup = ''
          makeWrapper "$out/lib/collie/bin/collie" "$out/bin/collie"
        '';

        doInstallCheck = true;
        preInstallCheck = ''
          python3 ${./omp-fix-dt-verdef.py} "$out/lib/collie/bin/collie"
        '';
        installCheckPhase = ''
          runHook preInstallCheck
          "$out/bin/collie" version | grep -F "${version}"
          test -f "$out/lib/collie/web/dist/index.html"
          runHook postInstallCheck
        '';

        meta = {
          description = "Mobile web UI for terminal AI agents (GitHub release binary)";
          homepage = "https://github.com/AltanS/collie";
          changelog = "https://github.com/AltanS/collie/releases/tag/v${version}";
          license = lib.licenses.mit;
          mainProgram = "collie";
          platforms = builtins.attrNames sources;
          sourceProvenance = [lib.sourceTypes.binaryNativeCode];
        };
      }
  ) {};
}
