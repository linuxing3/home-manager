_final: prev: {
  cli-proxy-api = prev.callPackage (
    {
      lib,
      stdenv,
      fetchurl,
    }: let
      version = "7.2.136";
      srcs = {
        aarch64-linux = {
          url = "https://github.com/router-for-me/CLIProxyAPI/releases/download/v${version}/CLIProxyAPI_${version}_linux_aarch64.tar.gz";
          hash = "sha256-6L5gfKr3x2/YHNxIOv41Riz09uIJ5bb0G9DHcC6KSxA=";
        };
        x86_64-linux = {
          url = "https://github.com/router-for-me/CLIProxyAPI/releases/download/v${version}/CLIProxyAPI_${version}_linux_amd64.tar.gz";
          hash = "sha256-j5FgmCvC8mFC97dqc/zFD5VMRTRw1aau+oEyStGNoog=";
        };
      };
      srcInfo =
        srcs.${stdenv.hostPlatform.system}
        or (throw "cli-proxy-api: unsupported system ${stdenv.hostPlatform.system}");
    in
      stdenv.mkDerivation {
        pname = "cli-proxy-api";
        inherit version;

        src = fetchurl srcInfo;

        sourceRoot = ".";

        installPhase = ''
          runHook preInstall
          mkdir -p "$out/bin"
          install -m755 cli-proxy-api "$out/bin/cli-proxy-api"
          runHook postInstall
        '';

        meta = with lib; {
          description = "OpenAI-compatible proxy for CLI coding agents";
          homepage = "https://github.com/router-for-me/CLIProxyAPI";
          license = licenses.mit;
          mainProgram = "cli-proxy-api";
          platforms = ["aarch64-linux" "x86_64-linux"];
          sourceProvenance = [sourceTypes.binaryNativeCode];
        };
      }
  ) {};
}
