{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.features.home;
  alacrittyWrapped = pkgs.symlinkJoin {
    name = "alacritty-wrapped";
    paths = [pkgs.alacritty];
    nativeBuildInputs = [pkgs.makeWrapper];
    meta.mainProgram = "alacritty";
    postBuild = ''
      wrapProgram $out/bin/alacritty \
        --set __EGL_VENDOR_LIBRARY_DIRS ${pkgs.mesa}/share/glvnd/egl_vendor.d \
        --set LIBGL_DRIVERS_PATH ${pkgs.mesa}/lib/dri \
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [pkgs.mesa pkgs.libglvnd]}
    '';
  };

  # Luke Smith st (plus this repo's Ctrl+Shift clipboard patch).
  # MODKEY = Alt, TERMMOD = Alt+Shift. Alt+a/s alpha has no Alacritty action.
  stBindings = [
    {
      key = "C";
      mods = "Alt";
      action = "Copy";
    }
    {
      key = "V";
      mods = "Alt";
      action = "Paste";
    }
    {
      key = "C";
      mods = "Alt|Shift";
      action = "Copy";
    }
    {
      key = "V";
      mods = "Alt|Shift";
      action = "Paste";
    }
    {
      key = "C";
      mods = "Control|Shift";
      action = "Copy";
    }
    {
      key = "V";
      mods = "Control|Shift";
      action = "Paste";
    }
    {
      key = "Insert";
      mods = "Shift";
      action = "Paste";
    }
    {
      key = "PageUp";
      mods = "Shift";
      action = "ScrollPageUp";
    }
    {
      key = "PageDown";
      mods = "Shift";
      action = "ScrollPageDown";
    }
    {
      key = "PageUp";
      mods = "Alt";
      action = "ScrollPageUp";
    }
    {
      key = "PageDown";
      mods = "Alt";
      action = "ScrollPageDown";
    }
    {
      key = "K";
      mods = "Alt";
      action = "ScrollLineUp";
    }
    {
      key = "J";
      mods = "Alt";
      action = "ScrollLineDown";
    }
    {
      key = "Up";
      mods = "Alt";
      action = "ScrollLineUp";
    }
    {
      key = "Down";
      mods = "Alt";
      action = "ScrollLineDown";
    }
    {
      key = "U";
      mods = "Alt";
      action = "ScrollPageUp";
    }
    {
      key = "D";
      mods = "Alt";
      action = "ScrollPageDown";
    }
    {
      key = "PageUp";
      mods = "Alt|Shift";
      action = "IncreaseFontSize";
    }
    {
      key = "PageDown";
      mods = "Alt|Shift";
      action = "DecreaseFontSize";
    }
    {
      key = "Home";
      mods = "Alt|Shift";
      action = "ResetFontSize";
    }
    {
      key = "Up";
      mods = "Alt|Shift";
      action = "IncreaseFontSize";
    }
    {
      key = "Down";
      mods = "Alt|Shift";
      action = "DecreaseFontSize";
    }
    {
      key = "K";
      mods = "Alt|Shift";
      action = "IncreaseFontSize";
    }
    {
      key = "J";
      mods = "Alt|Shift";
      action = "DecreaseFontSize";
    }
    {
      key = "U";
      mods = "Alt|Shift";
      action = "IncreaseFontSize";
    }
    {
      key = "D";
      mods = "Alt|Shift";
      action = "DecreaseFontSize";
    }
  ];
in {
  options.my.features.home.alacritty =
    lib.mkEnableOption "Alacritty with Luke Smith st keybindings";

  config = lib.mkIf cfg.alacritty {
    programs.alacritty = {
      enable = true;
      package = alacrittyWrapped;
      settings = {
        window = {
          opacity = 0.4;
          padding = {
            x = 2;
            y = 2;
          };
        };
        font.size = lib.mkForce 14;
        mouse.hide_when_typing = true;
        hints.enabled = [
          {
            regex = "(ipfs:|ipns:|magnet:|mailto:|gemini://|gopher://|https://|http://|news:|file:|git://|ssh:|ftp://)[^<>\"\\s]+";
            hyperlinks = true;
            command = lib.getExe' pkgs.xdg-utils "xdg-open";
            binding = {
              key = "L";
              mods = "Alt";
            };
          }
          {
            regex = "(ipfs:|ipns:|magnet:|mailto:|gemini://|gopher://|https://|http://|news:|file:|git://|ssh:|ftp://)[^<>\"\\s]+";
            hyperlinks = true;
            action = "Copy";
            binding = {
              key = "Y";
              mods = "Alt";
            };
          }
        ];
        keyboard.bindings = stBindings;
      };
    };
  };
}
