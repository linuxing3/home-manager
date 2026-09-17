_final: prev: {
  cliamp = prev.callPackage (
    {
      lib,
      stdenvNoCC,
      fetchurl,
      autoPatchelfHook,
      makeWrapper,
      alsa-lib,
      alsa-plugins,
      pipewire,
      symlinkJoin,
      ffmpeg-headless,
      yt-dlp,
    }: let
      version = "2.2.0";
      sources = {
        aarch64-linux = {
          url = "https://github.com/bjarneo/cliamp/releases/download/v${version}/cliamp-linux-arm64";
          hash = "sha256-lK459a3kt2IpPEecEgJCkltwGHywkQHJyeqRH0gRqLQ=";
        };
        x86_64-linux = {
          url = "https://github.com/bjarneo/cliamp/releases/download/v${version}/cliamp-linux-amd64";
          hash = "sha256-YP0zXjZ9kg+/qJimyH5BlhastV5xLhe1Q5q3Vz9g2II=";
        };
      };
      srcInfo =
        sources.${stdenvNoCC.hostPlatform.system}
          or (throw "cliamp: unsupported system ${stdenvNoCC.hostPlatform.system}");
      alsaPluginDir = symlinkJoin {
        name = "cliamp-alsa-plugins";
        paths = [
          "${alsa-plugins}/lib/alsa-lib"
          "${pipewire}/lib/alsa-lib"
        ];
      };
    in
      stdenvNoCC.mkDerivation {
        pname = "cliamp";
        inherit version;

        src = fetchurl srcInfo;
        dontUnpack = true;

        nativeBuildInputs = [
          autoPatchelfHook
          makeWrapper
        ];
        buildInputs = [alsa-lib];

        installPhase = ''
          runHook preInstall
          install -Dm755 "$src" "$out/bin/cliamp"
          wrapProgram "$out/bin/cliamp" \
            --prefix PATH : ${lib.makeBinPath [
            ffmpeg-headless
            yt-dlp
          ]} \
            --set-default ALSA_PLUGIN_DIR ${alsaPluginDir}
          runHook postInstall
        '';

        meta = {
          description = "Terminal music player with streaming, playlists, and visualizers";
          homepage = "https://www.cliamp.stream/";
          license = lib.licenses.mit;
          mainProgram = "cliamp";
          platforms = builtins.attrNames sources;
        };
      }
  ) {};
}
