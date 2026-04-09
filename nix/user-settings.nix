{ nixpkgs, systemSettings }:
rec {
  username = import ./username.nix; # username
  name = username; # name/identifier
  nickname = "linuxing3"; # email (used for certain configurations)
  realname = "Xing Wenju"; # email (used for certain configurations)
  email = "linuxing3@qq.com"; # email (used for certain configurations)
  emailAlt = "xingwenju@gmail.com"; # email (used for certain configurations)
  dotfilesDir = "/home/${username}/.config/home-manager"; # absolute path of the local repo
  initialHashedPassword = "$7$CU..../....qejXlflvte/eOFsclGcRG0$vPxrUfc8MZh/9VY1py86B8GVs516vrQcScjvN/YEs5B";
  mainSshAuthorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOm5HPR9bV+g/kWwDLzBCgCIija6GnHseUEthM+vX40l linuxing3@qq.com"
  ];
  theme = "io"; # selcted theme from my themes directory (./themes/)
  wm = "deepin"; # Selected window manager or desktop environment; must select one in both ./user/wm/ and ./system/wm/
  # window manager type translator; force X11 across modules
  wmType = "x11";
  browser = "chromium-browser"; # Default browser; must select one from ./user/app/browser/
  spawnBrowser =
    if ((browser == "qutebrowser") && (wm == "hyprland")) then
      "qutebrowser-hyprprofile"
    else
      (
        if (browser == "qutebrowser") then
          "qutebrowser --qt-flag enable-gpu-rasterization --qt-flag enable-native-gpu-memory-buffers --qt-flag num-raster-threads=4"
        else
          browser
      ); # Browser spawn command must be specail for qb, since it doesn't gpu accelerate by default (why?)
  defaultRoamDir = "Personal.p"; # Default org roam directory relative to ~/Org
  term = "kitty"; # Default terminal command;
  font = "Iosevka Nerd Font Mono"; # Selected font
  fontPkg = nixpkgs.legacyPackages.${systemSettings.system}.intel-one-mono; # Font package
  editor = "hx"; # Default editor;
  alterEditor = "emacsclient"; # Default editor;
  # editor spawning translator
  # generates a command that can be used to spawn editor inside a gui
  # EDITOR and TERM session variables must be set in home.nix or other module
  # I set the session variable SPAWNEDITOR to this in my home.nix for convenience
  spawnEditor =
    if (editor == "emacsclient") then
      "emacsclient -c -a 'emacs'"
    else
      (
        if ((editor == "vim") || (editor == "nvim") || (editor == "nano") || (editor == "hx")) then
          "exec " + term + " -e " + editor
        else
          (
            if (editor == "neovide") then
              "neovide -- --listen /tmp/nvimsocket"
            else
              "exec " + term + " -e " + alterEditor
          )
      );
}
