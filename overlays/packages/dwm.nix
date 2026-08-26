_final: prev: {
  dwm =
    (prev.dwm.override {
      conf = ../../modules/wm/dwm/config.h;
      patches = [./dwm-vanitygaps-dwm.c.diff];
    }).overrideAttrs (old: {
      postPatch =
        ''
          cp ${./vanitygaps.c} vanitygaps.c
        ''
        + (old.postPatch or "");
    });
}
