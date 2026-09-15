{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.ai.agentlyMail;
  agentlyCli = pkgs.stdenvNoCC.mkDerivation {
    pname = "agently-cli";
    version = "1.0.18";

    src = pkgs.fetchzip {
      url = "https://registry.npmjs.org/@tencent-qqmail/agently-cli-linux-arm64/-/agently-cli-linux-arm64-1.0.18.tgz";
      hash = "sha256-0ZNMl3mQHhrFKbI0J2ZjvMqH4G8TEcJ3ZLpxuNjtaTY=";
    };

    installPhase = ''
      install -Dm755 bin/agently-cli "$out/bin/agently-cli"
    '';

    meta = {
      description = "Agent-first mail CLI for Agently";
      homepage = "https://agent.qq.com";
      license = lib.licenses.asl20;
      platforms = ["aarch64-linux"];
    };
  };
in {
  options.my.ai.agentlyMail = {
    enable = lib.mkEnableOption "Agently Mail CLI";
    package = lib.mkOption {
      type = lib.types.package;
      default = agentlyCli;
      description = "Agently Mail CLI package.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [cfg.package];
  };
}
