{pkgs, ...}: {
  # Collection of useful GUI apps
  imports = [
    ../../modules/app/browser/qutebrowser.nix
    ../../modules/app/browser/brave.nix
  ];
  home.packages = with pkgs; [
    # explorer
    nautilus
    pcmanfm

    # blender
    # libreoffice

    xterm
    xclip
    groff

    # images
    imv
    sxiv
    nsxiv

    # pdf
    zathura
    xdotool 

    # Media
    # gimp
    vlc
    mpv
    viu

  ];

}
