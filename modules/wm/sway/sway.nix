{
  lib,
  pkgs,
  userSettings,
  ...
}:
let
  mod = "Mod4";
in
{
  home.packages = with pkgs; [
    swaybg
    swayidle
    swaylock
    waybar
    wofi
    wl-clipboard
    grim
    slurp
    kanshi
    wayland
    wayland-protocols
    libxkbcommon
    fcitx5
    fcitx5-gtk
    fcitx5-rime
  ];

  home.sessionVariables = {
    XDG_SESSION_TYPE = "wayland";
    XDG_CURRENT_DESKTOP = "sway";
    XDG_SESSION_DESKTOP = "sway";
    # On UOS/non-NixOS, use host GLVND/DRI paths for wlroots on the X11 backend.
    __EGL_VENDOR_LIBRARY_FILENAMES = "/usr/share/glvnd/egl_vendor.d/50_mesa.json";
    LIBGL_DRIVERS_PATH = "/usr/lib/aarch64-linux-gnu/dri";
    # Keep a reliable fallback renderer when DRM driver init is unavailable.
    WLR_RENDERER = "pixman";
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland;xcb";
    GDK_BACKEND = "wayland,x11,*";
    SDL_VIDEODRIVER = "wayland";
    CLUTTER_BACKEND = "wayland";
    XMODIFIERS = "@im=fcitx";
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    SDL_IM_MODULE = "fcitx";
    INPUT_METHOD = "fcitx";
    GLFW_IM_MODULE = "ibus";
  };

  wayland.windowManager.sway = {
    enable = true;
    package = pkgs.sway;
    wrapperFeatures.gtk = true;
    systemd.enable = true;
    config = {
      modifier = mod;
      terminal = userSettings.term;
      menu = "wofi --show drun";

      startup = [
        {
          command = "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway XDG_SESSION_TYPE=wayland XMODIFIERS GTK_IM_MODULE QT_IM_MODULE SDL_IM_MODULE INPUT_METHOD";
          always = true;
        }
        {
          command = "fcitx5 -d --replace";
          always = true;
        }
        {
          command = "waybar";
        }
      ];

      keybindings = lib.mkOptionDefault {
        "${mod}+Return" = "exec ${userSettings.term}";
        "${mod}+d" = "exec wofi --show drun";
        "${mod}+Shift+q" = "kill";
      };
    };
  };
}
