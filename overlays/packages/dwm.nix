{ inputs }:
final: prev:
{
  dwm = prev.st.overrideAttrs (oldAttrs: {
    pname = "dwm-xyz";
    version = "1.0.0";
    src = fetchTarball {
      url = "https://github.com/LukeSmithxyz/dwm/archive/master.tar.gz";
      sha256 = "0d0j5g8jy2wx181q47v9410l1n53y3c8ay4m9r1dw6lhmcr8zr13";
    };
    buildInputs = oldAttrs.buildInputs ++ (with prev; [ harfbuzz  xorg.libXinerama ]);
    postPatch = ''
      sed -i 's|"libwolf"|"brave"|' config.h
    '';
  });
}
