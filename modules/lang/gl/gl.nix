{ config, lib, pkgs, ... }:
let
  cfg = config.my.features.home;
in
{
  options.my.features.home.gl = lib.mkEnableOption "Enable graphics/OpenGL dev libraries module";

  config = lib.mkIf cfg.gl {
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
  };
}
