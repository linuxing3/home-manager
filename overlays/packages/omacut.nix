_final: prev: {
  omacut = prev.callPackage (
    {
      lib,
      stdenv,
      fetchFromGitHub,
      qt6,
      ffmpeg,
      makeWrapper,
    }:
      stdenv.mkDerivation {
        pname = "omacut";
        version = "0-unstable-2026-09-17";

        src = fetchFromGitHub {
          owner = "omacom";
          repo = "omacut";
          rev = "0948c4615d45ac62727b8c69112178e09781b7a4";
          hash = "sha256-vnncMfpx/mH6MZ0K1RIP498qAjOG+hf8Sdko+MVEX9w=";
        };

        nativeBuildInputs = [
          qt6.qmake
          qt6.wrapQtAppsHook
          makeWrapper
        ];

        buildInputs = [
          qt6.qtbase
          qt6.qtdeclarative
          qt6.qtmultimedia
        ];

        qmakeFlags = ["omacut.pro"];

        installPhase = ''
          runHook preInstall
          install -Dm755 omacut "$out/bin/omacut"
          install -Dm644 pkgbuild/omacut.desktop "$out/share/applications/omacut.desktop"
          install -Dm644 pkgbuild/omacut.svg "$out/share/icons/hicolor/scalable/apps/omacut.svg"
          runHook postInstall
        '';

        postFixup = ''
          wrapProgram "$out/bin/omacut" \
            --prefix PATH : ${lib.makeBinPath [ffmpeg]}
        '';

        meta = with lib; {
          description = "Dead-simple video length trimmer from Omarchy";
          homepage = "https://github.com/omacom/omacut";
          license = licenses.mit;
          mainProgram = "omacut";
          platforms = platforms.linux;
        };
      }
  ) {};
}
