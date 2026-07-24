{inputs}: final: prev: {
  rtk = prev.stdenvNoCC.mkDerivation {
    pname = "rtk";
    version = "0.43.0";

    src = prev.fetchurl {
      url = "https://github.com/rtk-ai/rtk/releases/download/v0.43.0/rtk-x86_64-unknown-linux-musl.tar.gz";
      hash = "sha256-/4oed2ZJbhdSkaha7KHcl8n/bfM+UeWJPR+8eP6ipgk=";
    };

    sourceRoot = ".";

    installPhase = ''
      runHook preInstall
      install -Dm755 rtk "$out/bin/rtk"
      runHook postInstall
    '';

    meta = with prev.lib; {
      description = "Token-optimized proxy for AI coding agent shell commands";
      homepage = "https://github.com/rtk-ai/rtk";
      license = licenses.asl20;
      mainProgram = "rtk";
      platforms = ["x86_64-linux"];
    };
  };
}
