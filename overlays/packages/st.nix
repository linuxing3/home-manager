{inputs}: final: prev: {
  st-xyz = prev.st.overrideAttrs (oldAttrs: {
    pname = "st-xyz";
    version = "0-unstable-2026-04-10";
    src = fetchTarball {
      url = "https://github.com/LukeSmithxyz/st/archive/48b8ee6e181643800fe83353ec554f503020a8fa.tar.gz";
      sha256 = "sha256-XFf48+6I3IHcRKGHRJIJb9u2sTKWyuWTb5lN+BILYYc=";
    };
    buildInputs = oldAttrs.buildInputs ++ (with prev; [harfbuzz]);
    patches = (oldAttrs.patches or []) ++ [./st-reload-xrdb.patch];
    postPatch = ''
           sed -i 's|"NotoColorEmoji:pixelsize=10:antialias=true:autohint=true" }|"NotoColorEmoji:pixelsize=10:antialias=true:autohint=true", "Source Han Sans SC:pixelsize=16:antialias=true:autohint=true" }|' config.h
           sed -i '/"fontalt0", STRING, \\&font2\\[0\\]/a\\\t{ "fontalt1", STRING, \\&font2[1] },' config.h
           substituteInPlace config.h \
             --replace-fail '{ TERMMOD,              XK_C,           clipcopy,       {.i =  0} },' \
                            '{ TERMMOD,              XK_C,           clipcopy,       {.i =  0} },
      { ControlMask|ShiftMask, XK_C,           clipcopy,       {.i =  0} },
      { ControlMask|ShiftMask, XK_V,           clippaste,      {.i =  0} },' \
             --replace-fail '{ XK_BackSpace,     XK_NO_MOD,      "\177",          0,    0},' \
                            '{ XK_BackSpace,     XK_NO_MOD,      "\x7f",          0,    0},' \
             --replace-fail '{ XK_BackSpace,     Mod1Mask,       "\033\177",      0,    0},' \
                            '{ XK_BackSpace,     Mod1Mask,       "\033\x7f",      0,    0},'
           substituteInPlace st.c \
             --replace-fail \
               $'\tif (openpty(&m, &s, NULL, NULL, NULL) < 0)\n\t\tdie("openpty failed: %s\\n", strerror(errno));' \
               $'\tif (openpty(&m, &s, NULL, NULL, NULL) < 0)\n\t\tdie("openpty failed: %s\\n", strerror(errno));\n\n\tstruct termios ttyattr;\n\tif (tcgetattr(s, &ttyattr) == 0) {\n\t\tttyattr.c_cc[VERASE] = 0x7f;\n\t\ttcsetattr(s, TCSANOW, &ttyattr);\n\t}'
    '';
    meta =
      (oldAttrs.meta or {})
      // {
        description = "Luke Smith's fork of st";
        homepage = "https://github.com/LukeSmithxyz/st";
        mainProgram = "st";
      };
  });
}
