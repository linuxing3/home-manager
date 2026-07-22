{ config, lib, pkgs, ... }:
let
  cfg = config.my.features.home;
in
{
  options.my.features.home.cc = lib.mkEnableOption "Enable C/C++ toolchain module";

  config = lib.mkIf cfg.cc {
    home.packages = with pkgs; [
      # CC
      gcc
      libllvm

      gnumake
      cmake
      premake5
      xmake
      meson

      autoconf
      automake
      libtool
    ];
  };
}
