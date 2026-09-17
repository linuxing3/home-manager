_final: prev: {
  aether = prev.callPackage (
    {
      lib,
      stdenvNoCC,
      fetchurl,
      dpkg,
      autoPatchelfHook,
      wrapGAppsHook3,
      glib,
      webkitgtk_4_1,
      gtk3,
      gdk-pixbuf,
      libsoup_3,
    }:
      stdenvNoCC.mkDerivation rec {
        pname = "aether";
        version = "4.29.9";

        src = fetchurl {
          url = "https://github.com/omacom/aether/releases/download/v${version}/aether_${version}_arm64.deb";
          hash = "sha256-aCcnfS9Rx0kt52n/E0lgK84Z1Tq+Lm06OabvSRKXzNU=";
        };

        nativeBuildInputs = [
          dpkg
          autoPatchelfHook
          wrapGAppsHook3
        ];

        buildInputs = [
          glib
          webkitgtk_4_1
          gtk3
          gdk-pixbuf
          libsoup_3
        ];

        dontConfigure = true;
        dontBuild = true;

        unpackPhase = ''
          dpkg-deb -x "$src" .
        '';

        installPhase = ''
          runHook preInstall
          mkdir -p "$out"
          cp -r usr/* "$out/"
          runHook postInstall
        '';

        meta = with lib; {
          description = "Visual desktop theme and wallpaper palette generator for Omarchy";
          homepage = "https://github.com/omacom/aether";
          license = licenses.mit;
          mainProgram = "aether";
          platforms = ["aarch64-linux"];
        };
      }
  ) {};
}
