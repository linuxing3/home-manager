{inputs}: final: prev: let
  sources = {
    x86_64-linux = {
      url = "https://github.com/dmtrKovalenko/fff/releases/download/v0.10.1/fff-mcp-x86_64-unknown-linux-musl";
      hash = "sha256-wXY3wzOvu73qSwPPPhVzJAxBR64SF1bjY6r6PJ0O+1g=";
    };
    aarch64-linux = {
      url = "https://github.com/dmtrKovalenko/fff/releases/download/v0.10.1/fff-mcp-aarch64-unknown-linux-musl";
      hash = "sha256-KiUBkQHuk3MyfavXrB1IAGOGiOlbZ7+zvsRBv42Tjyg=";
    };
  };
in {
  fff-mcp = prev.stdenvNoCC.mkDerivation {
    pname = "fff-mcp";
    version = "0.10.1";

    src = prev.fetchurl sources.${prev.stdenv.hostPlatform.system};

    dontUnpack = true;

    installPhase = ''
      runHook preInstall
      install -Dm755 "$src" "$out/bin/fff-mcp"
      runHook postInstall
    '';

    meta = with prev.lib; {
      description = "Fast file finder and grep MCP server";
      homepage = "https://github.com/dmtrKovalenko/fff";
      license = licenses.mit;
      mainProgram = "fff-mcp";
      platforms = ["x86_64-linux" "aarch64-linux"];
    };
  };
}
