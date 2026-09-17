{
  pkgs,
  lib,
  ...
}:
let
  nnnStScript = pkgs.writeShellApplication {
    name = "nnn-st";
    runtimeInputs = with pkgs; [
      st-xyz
      nnn
      coreutils
    ];
    text = ''
      if [ $# -eq 0 ]; then
        exec st -e nnn
      fi

      target="$1"
      target="''${target#file://}"
      if [ -f "$target" ]; then
        target="$(dirname "$target")"
      fi

      exec st -e nnn "$target"
    '';
  };
in
{
  home.packages = [
    nnnStScript
    pkgs.desktop-file-utils
  ];

  xdg.desktopEntries.nnn = {
    name = "nnn";
    genericName = "File Manager";
    comment = "Terminal file manager in st";
    exec = "st -e nnn %F";
    icon = "utilities-terminal";
    terminal = false;
    categories = [
      "System"
      "FileTools"
      "FileManager"
      "ConsoleOnly"
    ];
    mimeType = [ "inode/directory" ];
    settings = {
      Keywords = "File;Manager;Management;Explorer;Launcher;";
    };
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "inode/directory" = lib.mkForce "nnn.desktop";
      "text/html" = "brave-browser.desktop";
      "x-scheme-handler/http" = "brave-browser.desktop";
      "x-scheme-handler/https" = "brave-browser.desktop";
      "x-scheme-handler/about" = "brave-browser.desktop";
      "x-scheme-handler/unknown" = "brave-browser.desktop";
      "x-scheme-handler/grokbot" = "grok-bot.desktop";
      "x-scheme-handler/sand" = "grok-bot.desktop";
      "x-scheme-handler/codex" = "chatgpt.desktop";
      "x-scheme-handler/orca" = "orca-ide.desktop";
      "x-scheme-handler/obsidian" = "obsidian.desktop";
    };
    associations.added = {
      "inode/directory" = lib.mkForce [ "nnn.desktop" ];
      "x-scheme-handler/grokbot" = [ "grok-bot.desktop" ];
      "x-scheme-handler/sand" = [ "grok-bot.desktop" ];
      "x-scheme-handler/orca" = [ "orca-ide.desktop" ];
    };
  };

  home.sessionVariables = {
    DEFAULT_FILE_EXPLORER = "nnn-st";
  };

  home.activation.updateDesktopDatabase = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    if [[ -d "$HOME/.local/share/applications" ]]; then
      ${pkgs.desktop-file-utils}/bin/update-desktop-database "$HOME/.local/share/applications" || true
    fi
  '';
}
