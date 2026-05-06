{ inputs }:
final: prev:
let
  hermesUpstreamInputs = inputs.hermes-agent.inputs;
  hermesSrc = prev.runCommand "hermes-agent-source-patched" { } ''
    cp -r ${inputs.hermes-agent.outPath} $out
    chmod -R u+w $out
    sed -i 's/"hermes_time", "rl_cli"/"hermes_time", "hermes_logging", "rl_cli"/' \
      $out/pyproject.toml
  '';
  hermesVenv = final.callPackage "${hermesSrc}/nix/python.nix" {
    inherit
      (hermesUpstreamInputs)
      pyproject-build-systems
      pyproject-nix
      uv2nix
      ;
  };
  hermesBundledSkills = final.lib.cleanSourceWith {
    src = "${hermesSrc}/skills";
    filter = path: _type: !(final.lib.hasInfix "/index-cache/" path);
  };
  hermesRuntimeDeps = with final; [
    ffmpeg
    git
    nodejs_20
    openssh
    ripgrep
  ];
in
{
  hermes-agent = final.stdenv.mkDerivation {
    pname = "hermes-agent";
    version = "0.12.0+patched";

    dontUnpack = true;
    dontBuild = true;
    nativeBuildInputs = [ final.makeWrapper ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/share/hermes-agent $out/bin
      cp -r ${hermesBundledSkills} $out/share/hermes-agent/skills

      ${final.lib.concatMapStringsSep "\n" (name: ''
        makeWrapper ${hermesVenv}/bin/${name} $out/bin/${name} \
          --suffix PATH : "${final.lib.makeBinPath hermesRuntimeDeps}" \
          --set HERMES_BUNDLED_SKILLS $out/share/hermes-agent/skills
      '') [ "hermes" "hermes-agent" "hermes-acp" ]}

      runHook postInstall
    '';

    meta = with final.lib; {
      description = "AI agent with advanced tool-calling capabilities";
      homepage = "https://github.com/NousResearch/hermes-agent";
      mainProgram = "hermes";
      license = licenses.mit;
      platforms = platforms.unix;
    };
  };
}
