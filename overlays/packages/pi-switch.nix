{inputs}: final: prev: {
  pi-switch = prev.callPackage (
    {
      lib,
      stdenv,
      rustPlatform,
      fetchFromGitHub,
      makeWrapper,
      nodejs,
    }:
      rustPlatform.buildRustPackage rec {
        pname = "pi-switch";
        version = "20260807.0.0";

        src = fetchFromGitHub {
          owner = "heihei0299";
          repo = "pi-switch";
          rev = "v20260807";
          hash = "sha256-JJcHK51VVBK2uT+PdrK4aSAcu6vtm+e9iUZM23oYsJA=";
        };

        cargoHash = "sha256-+fwqHSSym1/Tz0WvexC49S038167an5hjeEHWwMNzZA=";

        nativeBuildInputs = [
          makeWrapper
          nodejs
        ];

        doCheck = false;
        dontCargoInstall = true;

        postPatch = ''
          mkdir -p webui/dist
          printf '%s\n' '<!doctype html><title>pi-switch</title>' >webui/dist/index.html
        '';

        installPhase = let
          nativeName =
            if stdenv.hostPlatform.isAarch64
            then "pi-switch-native.linux-arm64-gnu.node"
            else "pi-switch-native.linux-x64-gnu.node";
        in ''
          runHook preInstall
          mkdir -p "$out/libexec/pi-switch" "$out/bin"
          cp -r bin extensions index.js index.d.ts package.json pi-switch-native.cjs src \
            "$out/libexec/pi-switch/"
          so=$(find "''${CARGO_TARGET_DIR:-target}" -name 'libpi_switch_native.so' | head -n1)
          if [[ -z "$so" ]]; then
            echo "pi-switch: native library was not produced" >&2
            find "''${CARGO_TARGET_DIR:-target}" -maxdepth 5 -type f | sort >&2
            exit 1
          fi
          cp "$so" "$out/libexec/pi-switch/${nativeName}"
          makeWrapper ${lib.getExe nodejs} "$out/bin/pi-switch" \
            --add-flags "$out/libexec/pi-switch/bin/pi-switch.js"
          runHook postInstall
        '';

        meta = with lib; {
          description = "TUI and CLI profile switcher for the Pi coding agent";
          homepage = "https://github.com/heihei0299/pi-switch";
          license = licenses.mit;
          mainProgram = "pi-switch";
          platforms = ["x86_64-linux" "aarch64-linux"];
        };
      }
  ) {};
}
