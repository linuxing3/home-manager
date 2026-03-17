(self: super: {
  nnn = super.nnn.override (oldAttrs: {
      withNerdIcons = true;
    });
  st = super.st.overrideAttrs (oldAttrs: {
    pname = "st-xyz";
    version = "1.0.0";
    src = fetchTarball {
      url = "https://github.com/LukeSmithxyz/st/archive/master.tar.gz";
      sha256 = "1cqnl8zlxccqg0901gx21h06j9wk3ja6lr8wp4k85ni4msf4m09g";
    };
    buildInputs = oldAttrs.buildInputs ++ (with super; [ harfbuzz ]);
  });
  # g-lf = super.callPackage ./g-lf.nix { };
  # g-pistol = super.callPackage ./g-pistol.nix { };
})
