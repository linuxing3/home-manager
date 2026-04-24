{ config, lib, pkgs, ... }:

let
  cfg = config.my.features.home;
  googleChromeSupported = pkgs.stdenv.hostPlatform.system == "x86_64-linux";
  browserPackage =
    if googleChromeSupported
    then pkgs.google-chrome
    else pkgs.chromium;
  browserExecutable =
    if googleChromeSupported
    then "${browserPackage}/bin/google-chrome-stable"
    else "${browserPackage}/bin/chromium-browser";
  desktopFile =
    if googleChromeSupported
    then "google-chrome.desktop"
    else "chromium-browser.desktop";
in
{
  options.my.features.home.chrome = lib.mkEnableOption "Enable Chrome/Chromium browser module";

  config = lib.mkIf cfg.chrome {
    # Google Chrome is only packaged by Nixpkgs for x86_64-linux.
    # On aarch64-linux, install Chromium so the configured chromium-browser
    # command remains usable.
    home.packages = [ browserPackage ];

    home.sessionVariables = {
      DEFAULT_BROWSER = browserExecutable;
    };

    xdg.mimeApps.enable = true;
    xdg.mimeApps.defaultApplications = lib.genAttrs [
      "text/html"
      "x-scheme-handler/http"
      "x-scheme-handler/https"
      "x-scheme-handler/about"
      "x-scheme-handler/unknown"
    ] (_: desktopFile);
  };
}
