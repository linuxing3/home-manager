_final: prev: {
  omawrite = prev.callPackage (
    {
      lib,
      stdenv,
      fetchFromGitHub,
      qt6,
    }:
      stdenv.mkDerivation {
        pname = "omawrite";
        version = "0-unstable-2026-09-17";

        src = fetchFromGitHub {
          owner = "omacom";
          repo = "omawrite";
          rev = "8f98892b26768236b2c20f4e637cf4b102d898bf";
          hash = "sha256-yS3GOL/kc03qx4naWzUdSZwAYxMuCjvrgmhexpwjsfA=";
        };

        nativeBuildInputs = [
          qt6.qmake
          qt6.wrapQtAppsHook
        ];

        buildInputs = [
          qt6.qtbase
          qt6.qtdeclarative
          qt6.qtwayland
        ];

        qmakeFlags = ["omawrite.pro"];

        installPhase = ''
          runHook preInstall
          install -Dm755 omawrite "$out/bin/omawrite"
          install -Dm644 pkgbuild/omawrite.desktop "$out/share/applications/omawrite.desktop"
          install -Dm644 pkgbuild/omawrite.svg "$out/share/icons/hicolor/scalable/apps/omawrite.svg"
          runHook postInstall
        '';

        meta = with lib; {
          description = "Minimal writing app from Omarchy";
          homepage = "https://github.com/omacom/omawrite";
          license = licenses.mit;
          mainProgram = "omawrite";
          platforms = platforms.linux;
        };
      }
  ) {};
}
