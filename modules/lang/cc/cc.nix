{pkgs, ...}: {
  home.packages = with pkgs; [
    # CC
    gcc
    gnumake
    cmake
    premake5
    xmake
    autoconf
    automake
    libtool
    pkg-config
  ];
}
