_final: prev: {
  herdr = prev.callPackage (
    {
      lib,
      stdenv,
      fetchurl,
    }: let
      version = "0.9.3";
      sources = {
        aarch64-linux = {
          url = "https://github.com/herdrdev/herdr/releases/download/v${version}/herdr-linux-aarch64";
          hash = "sha256-TeeqPiVniBLpKWDeZPfCqqG8ofD4CjxeVZg34jHh9cA=";
        };
        x86_64-linux = {
          url = "https://github.com/herdrdev/herdr/releases/download/v${version}/herdr-linux-x86_64";
          hash = "sha256-KgL+0WvrZR7wBuHUPwSPZSyk3FitBTzS1ERQVj1cVLc=";
        };
      };
      srcInfo =
        sources.${stdenv.hostPlatform.system}
          or (throw "herdr: unsupported system ${stdenv.hostPlatform.system}");
    in
      # Upstream Linux releases are fully static; no patchelf required.
      stdenv.mkDerivation {
        pname = "herdr";
        inherit version;

        src = fetchurl srcInfo;
        dontUnpack = true;
        dontStrip = true;

        installPhase = ''
          runHook preInstall
          install -Dm755 "$src" "$out/bin/herdr"
          runHook postInstall
        '';

        doInstallCheck = true;
        installCheckPhase = ''
          runHook preInstallCheck
          "$out/bin/herdr" --version | grep -F "${version}"
          runHook postInstallCheck
        '';

        meta = {
          description = "Terminal multiplexer for AI coding agents (GitHub release binary)";
          homepage = "https://herdr.dev";
          changelog = "https://github.com/herdrdev/herdr/releases/tag/v${version}";
          license = lib.licenses.mit;
          mainProgram = "herdr";
          platforms = builtins.attrNames sources;
          sourceProvenance = [lib.sourceTypes.binaryNativeCode];
        };
      }
  ) {};
}
