(final: prev: {
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
})
