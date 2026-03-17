{ pkgs, ... }:
{
  home.packages = with pkgs; [
    libGL
    vulkan-headers
    vulkan-loader

    xorg.libXrandr
    xorg.libXinerama
    xorg.libXcursor
    xorg.libX11
    xorg.libXi
    xorg.libXext
    xorg.libXxf86vm
    libxkbcommon

    wayland
    wayland-scanner
    wayland-protocols


    # imgui
    # glfw
    # SDL2

    # alsa-lib
    # libpulseaudio

    # raylib
    # raylib-games
    # libGLU

    # vcpkg
  ];
}
