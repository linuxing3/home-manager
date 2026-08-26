{pkgs, ...}: {
  home.packages = [pkgs.flatpak];
  home.sessionVariables = {
    XDG_DATA_DIRS = "$XDG_DATA_DIRS:/run/current-system/sw/share:/usr/share:/var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share"; # lets flatpak work
  };

  #services.flatpak.enable = true;
  #services.flatpak.packages = [ { appId = "com.kde.kdenlive"; origin = "flathub";  } ];
  #services.flatpak.update.onActivation = true;
}
