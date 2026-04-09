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
    inherit (hermesUpstreamInputs)
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
    version = "0.7.0+patched";

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

  lancedb-mcp = final.callPackage ../modules/pkgs/lancedb-mcp.nix { };
  agent-browser = final.callPackage ../modules/pkgs/agent-browser.nix { };
  nnn = prev.nnn.override (oldAttrs: {
    withNerdIcons = true;
  });
  st = prev.st.overrideAttrs (oldAttrs: {
    pname = "st-xyz";
    version = "1.0.0";
    src = fetchTarball {
      url = "https://github.com/LukeSmithxyz/st/archive/master.tar.gz";
      sha256 = "1cqnl8zlxccqg0901gx21h06j9wk3ja6lr8wp4k85ni4msf4m09g";
    };
    buildInputs = oldAttrs.buildInputs ++ (with prev; [ harfbuzz ]);
    postPatch = ''
      sed -i 's|"NotoColorEmoji:pixelsize=10:antialias=true:autohint=true" }|"NotoColorEmoji:pixelsize=10:antialias=true:autohint=true", "Source Han Sans SC:pixelsize=16:antialias=true:autohint=true" }|' config.h
      sed -i '/"fontalt0", STRING, \&font2\[0\]/a\	{ "fontalt1", STRING, \&font2[1] },' config.h
    '';
  });
  libsForQt5 = prev.libsForQt5 // {
    fcitx5-with-addons = prev.qt6Packages.fcitx5-with-addons;
  };
  helix-steel-system = final.helix.overrideAttrs (old: {
    cargoBuildFeatures = (
      (old.cargoBuildFeatures or [ ])
      ++ [
        "git"
        "steel"
      ]
    );
  });
  opencode-desktop = prev.opencode-desktop.overrideAttrs (old: {
    cargoDeps = final.rustPlatform.importCargoLock {
      lockFile = old.src + "/packages/desktop/src-tauri/Cargo.lock";
      outputHashes = {
        "specta-2.0.0-rc.22" = "sha256-YsyOAnXELLKzhNlJ35dHA6KGbs0wTAX/nlQoW8wWyJQ=";
        "tauri-specta-2.0.0-rc.21" = "sha256-n2VJ+B1nVrh6zQoZyfMoctqP+Csh7eVHRXwUQuiQjaQ=";
      };
    };
  });
}
