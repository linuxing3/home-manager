{pkgs, ...}: {
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
}
