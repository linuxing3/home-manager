_final: prev: {
  omacalc = prev.callPackage (
    {
      lib,
      stdenv,
      fetchFromGitHub,
      qt6,
    }:
      stdenv.mkDerivation {
        pname = "omacalc";
        version = "0-unstable-2026-09-17";

        src = fetchFromGitHub {
          owner = "omacom";
          repo = "omacalc";
          rev = "dba63819810d0a3b1a0581f3bcafc9651dbfb85d";
          hash = "sha256-I+WxkMz/2hCf4OpJKu99+30c0CxyxFD0M6eSLFDLs1I=";
        };

        nativeBuildInputs = [
          qt6.qmake
          qt6.wrapQtAppsHook
        ];

        buildInputs = [
          qt6.qtbase
          qt6.qtdeclarative
        ];

        qmakeFlags = ["omacalc.pro"];

        installPhase = ''
          runHook preInstall
          install -Dm755 omacalc "$out/bin/omacalc"
          mkdir -p "$out/share/applications"
          cat > "$out/share/applications/omacalc.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Omacalc
GenericName=Calculator
Comment=Dead-simple calculator from Omarchy
Exec=omacalc
Icon=accessories-calculator
Terminal=false
Categories=Utility;Calculator;
Keywords=calc;calculator;math;
StartupWMClass=omacalc
EOF
          runHook postInstall
        '';

        meta = with lib; {
          description = "Dead-simple calculator from Omarchy";
          homepage = "https://github.com/omacom/omacalc";
          license = licenses.mit;
          mainProgram = "omacalc";
          platforms = platforms.linux;
        };
      }
  ) {};
}
