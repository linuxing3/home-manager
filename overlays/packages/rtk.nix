{inputs}: final: prev: let
  sources = {
    x86_64-linux = {
      url = "https://github.com/rtk-ai/rtk/releases/download/v0.43.0/rtk-x86_64-unknown-linux-musl.tar.gz";
      hash = "sha256-/4oed2ZJbhdSkaha7KHcl8n/bfM+UeWJPR+8eP6ipgk=";
    };
    aarch64-linux = {
      url = "https://github.com/rtk-ai/rtk/releases/download/v0.43.0/rtk-aarch64-unknown-linux-gnu.tar.gz";
      hash = "sha256-VRn3yhLlwUOmCfDSigp3uXQTqNzjHCaB8aQcJFGahzE=";
    };
  };
  isAarch64 = prev.stdenv.hostPlatform.isAarch64;
in {
  rtk = prev.stdenv.mkDerivation {
    pname = "rtk";
    version = "0.43.0";

    src = prev.fetchurl sources.${prev.stdenv.hostPlatform.system};

    sourceRoot = ".";

    nativeBuildInputs = prev.lib.optionals isAarch64 [prev.autoPatchelfHook];
    buildInputs = prev.lib.optionals isAarch64 [prev.stdenv.cc.cc.lib];

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
      platforms = ["x86_64-linux" "aarch64-linux"];
    };
  };
}
