{ inputs }:
final: prev:
{
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
      sed -i '/"fontalt0", STRING, \\&font2\\[0\\]/a\\\t{ "fontalt1", STRING, \\&font2[1] },' config.h
    '';
  });
}
