{pkgs, ...}: {
  # Collection of useful GUI apps
  home.packages = with pkgs; [
    # explorer
    nautilus
    pcmanfm

    # blender
    # libreoffice

    # xterm
    # xclip
    # groff

    # images
    imv
    sxiv
    nsxiv

    # pdf
    # zathura
    # xdotool 

    # Media
    # gimp
    vlc
    mpv
    viu

    # Browser
    librewolf

  ];

}
