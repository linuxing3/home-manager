{ pkgs, userSettings, ... }:
let
  buildFirefoxXpiAddon =
    {
      pname,
      version,
      addonId,
      url,
      sha256,
      meta ? { },
    }:
    pkgs.stdenvNoCC.mkDerivation {
      inherit pname version meta;
      src = pkgs.fetchurl { inherit url sha256; };
      dontUnpack = true;
      preferLocalBuild = true;
      allowSubstitutes = true;
      passthru = { inherit addonId; };
      installPhase = ''
        runHook preInstall
        install -Dm644 "$src" "$out/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/${addonId}.xpi"
        runHook postInstall
      '';
    };

  librewolfExtensions = {
    vimium = buildFirefoxXpiAddon {
      pname = "vimium";
      version = "2.4.2";
      addonId = "{d7742d87-e61d-4b78-b8a1-b469842139fa}";
      url = "https://addons.mozilla.org/firefox/downloads/file/4717567/vimium_ff-2.4.2.xpi";
      sha256 = "sha256-Ex4qZ1gOeukSWrGXgRWeYUCfrEe0Qfwngqq3Y5bq0ZY=";
      meta = with pkgs.lib; {
        description = "Vimium: Vim-like keyboard shortcuts for Firefox-compatible browsers";
        homepage = "https://addons.mozilla.org/firefox/addon/vimium-ff/";
        license = licenses.mit;
        platforms = platforms.all;
      };
    };

    bitwarden = buildFirefoxXpiAddon {
      pname = "bitwarden-password-manager";
      version = "2026.4.0";
      addonId = "{446900e4-71c2-419f-a6a7-df9c091e268b}";
      url = "https://addons.mozilla.org/firefox/downloads/file/4796063/bitwarden_password_manager-2026.4.0.xpi";
      sha256 = "sha256-zL32w6EchlXU/pvfz18WxMn/LYcy+tu4U5aiEjJ0rhA=";
      meta = with pkgs.lib; {
        description = "Bitwarden Password Manager browser extension";
        homepage = "https://addons.mozilla.org/firefox/addon/bitwarden-password-manager/";
        license = licenses.gpl3Only;
        platforms = platforms.all;
      };
    };

    obsidianWebClipper = buildFirefoxXpiAddon {
      pname = "obsidian-web-clipper";
      version = "1.6.1";
      addonId = "clipper@obsidian.md";
      url = "https://addons.mozilla.org/firefox/downloads/file/4774852/web_clipper_obsidian-1.6.1.xpi";
      sha256 = "sha256-KtlXh802TZ/Reds7K0ODKrOnCpJiiogbKgjj90dK2kM=";
      meta = with pkgs.lib; {
        description = "Official Obsidian Web Clipper browser extension";
        homepage = "https://addons.mozilla.org/firefox/addon/web-clipper-obsidian/";
        license = licenses.mit;
        platforms = platforms.all;
      };
    };

    youtubeToNotebookLM = buildFirefoxXpiAddon {
      pname = "youtube-to-notebooklm";
      version = "1.0.29";
      addonId = "yt.to.notebooklm@gmail.com";
      url = "https://addons.mozilla.org/firefox/downloads/file/4799340/youtube_to_notebooklm-1.0.29.xpi";
      sha256 = "sha256-q5mrrYFafChIwA6NZHCFYjzEjYpdGSB34p+Pl5Y5KtI=";
      meta = with pkgs.lib; {
        description = "Send YouTube videos to NotebookLM";
        homepage = "https://addons.mozilla.org/firefox/addon/youtube-to-notebooklm/";
        license = licenses.mit;
        platforms = platforms.all;
      };
    };
  };
in

{
  # Module installing librewolf as default browser

  programs.librewolf = {
    enable = true;
    package = if (userSettings.wmType == "wayland") then pkgs.librewolf-wayland else pkgs.librewolf;
    profiles.default = {
      id = 0;
      isDefault = true;
      extensions.packages = with librewolfExtensions; [
        vimium
        bitwarden
        obsidianWebClipper
        youtubeToNotebookLM
      ];
    };
  };


  home.sessionVariables = if (userSettings.wmType == "wayland")
                            then { DEFAULT_BROWSER = "${pkgs.librewolf-wayland}/bin/librewolf";}
                          else
                            { DEFAULT_BROWSER = "${pkgs.librewolf}/bin/librewolf";};

  home.file.".librewolf/librewolf.overrides.cfg".text = ''
    defaultPref("font.name.serif.x-western","''+userSettings.font+''");

    defaultPref("font.size.variable.x-western",20);
    defaultPref("browser.toolbars.bookmarks.visibility","always");
    defaultPref("privacy.resisttFingerprinting.letterboxing", true);
    defaultPref("network.http.referer.XOriginPolicy",2);
    defaultPref("privacy.clearOnShutdown.history",true);
    defaultPref("privacy.clearOnShutdown.downloads",true);
    defaultPref("privacy.clearOnShutdown.cookies",true);
    defaultPref("gfx.webrender.software.opengl",false);
    defaultPref("webgl.disabled",true);
    pref("font.name.serif.x-western","''+userSettings.font+''");

    pref("font.size.variable.x-western",20);
    pref("browser.toolbars.bookmarks.visibility","always");
    pref("privacy.resisttFingerprinting.letterboxing", true);
    pref("network.http.referer.XOriginPolicy",2);
    pref("privacy.clearOnShutdown.history",true);
    pref("privacy.clearOnShutdown.downloads",true);
    pref("privacy.clearOnShutdown.cookies",true);
    pref("gfx.webrender.software.opengl",false);
    pref("webgl.disabled",true);
    '';

  xdg.mimeApps.defaultApplications = {
  "text/html" = "librewolf.desktop";
  "x-scheme-handler/http" = "librewolf.desktop";
  "x-scheme-handler/https" = "librewolf.desktop";
  "x-scheme-handler/about" = "librewolf.desktop";
  "x-scheme-handler/unknown" = "librewolf.desktop";
  };

}
