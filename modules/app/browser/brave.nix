{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.features.home;
  braveKeybindingsBackup = builtins.fromJSON (builtins.readFile ./brave-keybindings-backup.json);

  braveShortcutsData = {
    captured_at = "2026-09-17";
    web_apps = [
      {
        name = "CapCut Web";
        app_id = "elkjmlbfikglemnpgkkhkgmmjbljhiom";
        exec = "brave --profile-directory=Default --app-id=elkjmlbfikglemnpgkkhkgmmjbljhiom";
      }
    ];
    top_sites = [
      {
        title = "Cloudflare";
        url = "https://cloudflare.com/";
      }
      {
        title = "QQ Mail";
        url = "https://mail.qq.com/";
      }
      {
        title = "Desk";
        url = "https://desk.efwmcstyle.ccwu.cc/";
      }
      {
        title = "ClickUp";
        url = "https://clickup.com/";
      }
      {
        title = "YouTube";
        url = "https://youtube.com/";
      }
      {
        title = "YouTube Studio";
        url = "https://studio.youtube.com/channel/UCUxueUdYXMADtWaco4ElpHQ";
      }
      {
        title = "Google Flow";
        url = "https://flow.google.com/";
      }
      {
        title = "Google Flow - Cooking Rice";
        url = "https://labs.google/fx/zh/tools/flow/project/8a7a45fd-c2d7-42a6-a955-42be66371b0f";
      }
      {
        title = "EfwmcApp Mail";
        url = "https://mail.efwmcapp.com/";
      }
      {
        title = "EfwmcApp";
        url = "https://efwmcapp.com/";
      }
      {
        title = "X (Twitter)";
        url = "https://x.com/";
      }
      {
        title = "Amazon";
        url = "https://amazon.com/";
      }
    ];
    omnibox_shortcuts = [
      {
        keyword = "nixos packages search";
        url = "https://search.brave.com/search?q=nixos+packages+search&source=desktop";
      }
      {
        keyword = "youtube";
        url = "https://search.brave.com/search?q=youtube&source=desktop";
      }
      {
        keyword = "cloudflare.com";
        url = "http://cloudflare.com/";
      }
      {
        keyword = "gmail";
        url = "https://search.brave.com/search?q=gmail&source=desktop";
      }
      {
        keyword = "x.com";
        url = "http://x.com/";
      }
      {
        keyword = "notebooklm skills";
        url = "https://search.brave.com/search?q=notebooklm+skills&source=desktop";
      }
    ];
    recent_shorts = [
      {
        title = "Tiny Chef Makes Golden Egg Fried Rice";
        url = "https://www.youtube.com/shorts/UqTB3qFGdJA";
      }
      {
        title = "Tiny Workers Make Hot Filter Coffee & Banana Fritters in the Rain";
        url = "https://www.youtube.com/shorts/eeKkm269rTI";
      }
      {
        title = "Mini Mansaf ASMR";
        url = "https://www.youtube.com/shorts/SLRUen4XYdM";
      }
      {
        title = "Mini Tagine ASMR";
        url = "https://www.youtube.com/shorts/szkecxDJk3M";
      }
      {
        title = "Mini Dongguan Sausage Rice ASMR";
        url = "https://www.youtube.com/shorts/SucXUFORSmg";
      }
    ];
  };

  # Full backup snapshot, retained as the declarative source of truth.
  braveKeybindingsData = {
    managed_at = "2026-09-18";
    description = "Brave keybindings restored from the 2026-09-18 backup";
    accelerators = braveKeybindingsBackup."brave.accelerators";
    default_accelerators = braveKeybindingsBackup."brave.default_accelerators";
    extension_commands = braveKeybindingsBackup."extensions.commands";
  };

  braveShortcutsScript = pkgs.writeShellApplication {
    name = "brave-shortcuts";
    runtimeInputs = with pkgs; [coreutils];
    text = ''
      # Interactive selector or command line dispatcher for Brave shortcuts & keybindings
      target="''${1:-}"

      print_keybindings() {
        cat ${./brave-keybindings-backup.md}
      }

      if [ -z "$target" ]; then
        if [ -t 0 ] && command -v fzf >/dev/null 2>&1; then
          target=$(printf '%s\n' \
            "keybindings" \
            "capcut-web" \
            "cloudflare" \
            "clickup" \
            "youtube" \
            "youtube-studio" \
            "google-flow" \
            "flow-cooking-rice" \
            "qq-mail" \
            "efwmcapp-mail" \
            "efwmcapp" \
            "desk" \
            "x" \
            "amazon" | fzf --prompt="Brave Shortcut > ")
        elif command -v dmenu >/dev/null 2>&1; then
          target=$(printf '%s\n' \
            "keybindings" \
            "capcut-web" \
            "cloudflare" \
            "clickup" \
            "youtube" \
            "youtube-studio" \
            "google-flow" \
            "flow-cooking-rice" \
            "qq-mail" \
            "efwmcapp-mail" \
            "efwmcapp" \
            "desk" \
            "x" \
            "amazon" | dmenu -i -p "Brave Shortcut:")
        else
          echo "Usage: brave-shortcuts <name|keybindings>"
          echo "Run 'brave-shortcuts list' to see all shortcuts."
          echo "Run 'brave-shortcuts keybindings' to view keyboard shortcuts."
          exit 0
        fi
      fi

      case "$target" in
        keys|keybindings|shortcuts|hotkeys)
          if [ "''${2:-}" = "--json" ]; then
            if [ -f "$HOME/.local/share/brave/keybindings.json" ]; then
              cat "$HOME/.local/share/brave/keybindings.json"
            else
              echo '{"error": "keybindings.json not found"}' >&2
              exit 1
            fi
          else
            print_keybindings
          fi
          ;;
        capcut|capcut-web)
          exec brave --profile-directory=Default --app-id=elkjmlbfikglemnpgkkhkgmmjbljhiom
          ;;
        cloudflare)
          exec brave --profile-directory=Default --app=https://cloudflare.com/
          ;;
        clickup)
          exec brave --profile-directory=Default --app=https://clickup.com/
          ;;
        youtube)
          exec brave --profile-directory=Default --app=https://youtube.com/
          ;;
        youtube-studio|studio)
          exec brave --profile-directory=Default --app=https://studio.youtube.com/channel/UCUxueUdYXMADtWaco4ElpHQ
          ;;
        google-flow|flow)
          exec brave --profile-directory=Default --app=https://flow.google.com/
          ;;
        flow-cooking-rice)
          exec brave --profile-directory=Default --app=https://labs.google/fx/zh/tools/flow/project/8a7a45fd-c2d7-42a6-a955-42be66371b0f
          ;;
        qq-mail|qqmail)
          exec brave --profile-directory=Default --app=https://mail.qq.com/
          ;;
        efwmcapp-mail)
          exec brave --profile-directory=Default --app=https://mail.efwmcapp.com/
          ;;
        efwmcapp)
          exec brave --profile-directory=Default --app=https://efwmcapp.com/
          ;;
        desk)
          exec brave --profile-directory=Default --app=https://desk.efwmcstyle.ccwu.cc/
          ;;
        x|twitter)
          exec brave --profile-directory=Default --app=https://x.com/
          ;;
        amazon)
          exec brave --profile-directory=Default --app=https://amazon.com/
          ;;
        list|--list|-l)
          echo "Available Brave shortcuts:"
          echo "  - keybindings         (Show all keyboard shortcuts and custom keybindings)"
          echo "  - capcut-web          (CapCut Web PWA)"
          echo "  - cloudflare          (https://cloudflare.com/)"
          echo "  - clickup             (https://clickup.com/)"
          echo "  - youtube             (https://youtube.com/)"
          echo "  - youtube-studio      (https://studio.youtube.com/channel/UCUxueUdYXMADtWaco4ElpHQ)"
          echo "  - google-flow         (https://flow.google.com/)"
          echo "  - flow-cooking-rice   (https://labs.google/fx/zh/tools/flow/project/...)"
          echo "  - qq-mail             (https://mail.qq.com/)"
          echo "  - efwmcapp-mail       (https://mail.efwmcapp.com/)"
          echo "  - efwmcapp            (https://efwmcapp.com/)"
          echo "  - desk                (https://desk.efwmcstyle.ccwu.cc/)"
          echo "  - x                   (https://x.com/)"
          echo "  - amazon              (https://amazon.com/)"
          ;;
        *)
          echo "Unknown shortcut: $target" >&2
          echo "Run 'brave-shortcuts list' for options or 'brave-shortcuts keybindings' for keybindings." >&2
          exit 1
          ;;
      esac
    '';
  };

  braveGeoScript = pkgs.writeShellApplication {
    name = "brave-geo";
    runtimeInputs = with pkgs; [
      brave
      coreutils
      curl
      dmenu
      fuzzel
      homedge-sync
      mihomo
      procps
      python3
    ];
    text = ''
      export BRAVE_GEO_INJECT=${../../pkgs/homedge-inject-listeners.py}
      exec python3 ${./brave-geo.py} "$@"
    '';
  };
in {
  options.my.features.home.brave = lib.mkEnableOption "Enable Brave browser module with managed shortcuts and keybindings";

  config = lib.mkIf cfg.brave {
    home.packages = [
      pkgs.brave
      braveShortcutsScript
      braveGeoScript
    ];

    # Full JSON snapshot of all Brave web shortcuts, top sites, and omnibox shortcuts
    xdg.dataFile."brave/shortcuts.json".text = builtins.toJSON braveShortcutsData;

    # Full declarative keybindings snapshot (accelerators, extension commands, descriptions)
    xdg.dataFile."brave/keybindings.json".text = builtins.toJSON braveKeybindingsData;

    # Declaratively sync and preserve Brave accelerators & extension keybindings in profile
    home.activation.mergeBravePreferences = lib.hm.dag.entryAfter ["writeBoundary"] ''
      set -eu

      preserve_once() {
        source=$1
        if [[ -f "$source" && ! -e "$source.hm-bak" ]]; then
          ${pkgs.coreutils}/bin/cp --preserve=mode,timestamps -- "$source" "$source.hm-bak"
        fi
      }

      brave_prefs="${config.home.homeDirectory}/.config/BraveSoftware/Brave-Browser/Default/Preferences"
      brave_kb_json=${pkgs.writeText "brave-keybindings.json" (builtins.toJSON braveKeybindingsData)}

      if [[ -f "$brave_prefs" ]]; then
        preserve_once "$brave_prefs"
        ${pkgs.python3}/bin/python3 ${./merge-brave-preferences.py} "$brave_prefs" "$brave_kb_json"
      fi
    '';

    # Desktop entries for Brave web apps and top-sites shortcuts
    xdg.desktopEntries = {
      brave-geo = {
        name = "Brave Geo";
        genericName = "Isolated Brave profiles by country IP";
        comment = "Fuzzel/dmenu launcher for clean Brave profiles on Homedge exits";
        exec = "brave-geo";
        icon = "brave-browser";
        terminal = false;
        categories = [
          "Network"
          "WebBrowser"
        ];
      };

      capcut-web = {
        name = "CapCut Web";
        genericName = "Video Editor";
        comment = "CapCut Web Video Editor";
        exec = "brave --profile-directory=Default --app-id=elkjmlbfikglemnpgkkhkgmmjbljhiom";
        icon = "brave-elkjmlbfikglemnpgkkhkgmmjbljhiom-Default";
        terminal = false;
        categories = [
          "AudioVideo"
          "Video"
          "AudioVideoEditing"
        ];
        settings = {
          StartupWMClass = "crx_elkjmlbfikglemnpgkkhkgmmjbljhiom";
        };
      };

      brave-cloudflare = {
        name = "Cloudflare";
        genericName = "Cloudflare Dashboard";
        comment = "Cloudflare: Build for the agent era";
        exec = "brave --profile-directory=Default --app=https://cloudflare.com/";
        icon = "brave-browser";
        terminal = false;
        categories = [
          "Network"
          "WebBrowser"
        ];
      };

      brave-clickup = {
        name = "ClickUp";
        genericName = "Project Management";
        comment = "ClickUp: Productivity platform";
        exec = "brave --profile-directory=Default --app=https://clickup.com/";
        icon = "brave-browser";
        terminal = false;
        categories = [
          "Office"
          "ProjectManagement"
        ];
      };

      brave-youtube = {
        name = "YouTube";
        genericName = "Video Platform";
        comment = "Watch and stream YouTube videos";
        exec = "brave --profile-directory=Default --app=https://youtube.com/";
        icon = "brave-browser";
        terminal = false;
        categories = [
          "AudioVideo"
          "Video"
        ];
      };

      brave-youtube-studio = {
        name = "YouTube Studio";
        genericName = "Creator Studio";
        comment = "Manage and edit YouTube channel content";
        exec = "brave --profile-directory=Default --app=https://studio.youtube.com/channel/UCUxueUdYXMADtWaco4ElpHQ";
        icon = "brave-browser";
        terminal = false;
        categories = [
          "AudioVideo"
          "Video"
        ];
      };

      brave-google-flow = {
        name = "Google Flow";
        genericName = "AI Creative Studio";
        comment = "Google Flow AI video and image studio";
        exec = "brave --profile-directory=Default --app=https://flow.google.com/";
        icon = "brave-browser";
        terminal = false;
        categories = [
          "Graphics"
          "AudioVideo"
        ];
      };

      brave-google-flow-project = {
        name = "Google Flow - Cooking Rice";
        genericName = "AI Flow Project";
        comment = "Google Flow project: cooking rice 2";
        exec = "brave --profile-directory=Default --app=https://labs.google/fx/zh/tools/flow/project/8a7a45fd-c2d7-42a6-a955-42be66371b0f";
        icon = "brave-browser";
        terminal = false;
        categories = [
          "Graphics"
          "AudioVideo"
        ];
      };

      brave-qq-mail = {
        name = "QQ Mail";
        genericName = "Email Client";
        comment = "QQ 邮箱";
        exec = "brave --profile-directory=Default --app=https://mail.qq.com/";
        icon = "brave-browser";
        terminal = false;
        categories = [
          "Network"
          "Email"
        ];
      };

      brave-efwmcapp-mail = {
        name = "EfwmcApp Mail";
        genericName = "Email Client";
        comment = "EfwmcApp Mail";
        exec = "brave --profile-directory=Default --app=https://mail.efwmcapp.com/";
        icon = "brave-browser";
        terminal = false;
        categories = [
          "Network"
          "Email"
        ];
      };

      brave-efwmcapp = {
        name = "EfwmcApp";
        genericName = "Home Finds Store";
        comment = "efwmcapp.com: Curated Home Finds";
        exec = "brave --profile-directory=Default --app=https://efwmcapp.com/";
        icon = "brave-browser";
        terminal = false;
        categories = [
          "Network"
          "WebBrowser"
        ];
      };

      brave-desk = {
        name = "Desk (EfwmcStyle)";
        genericName = "Directory Index";
        comment = "Desk Directory Listing";
        exec = "brave --profile-directory=Default --app=https://desk.efwmcstyle.ccwu.cc/";
        icon = "brave-browser";
        terminal = false;
        categories = [
          "Network"
          "WebBrowser"
        ];
      };

      brave-x = {
        name = "X (Twitter)";
        genericName = "Social Network";
        comment = "X (formerly Twitter)";
        exec = "brave --profile-directory=Default --app=https://x.com/";
        icon = "brave-browser";
        terminal = false;
        categories = [
          "Network"
          "Chat"
        ];
      };

      brave-amazon = {
        name = "Amazon";
        genericName = "Shopping";
        comment = "Amazon.com online shopping";
        exec = "brave --profile-directory=Default --app=https://amazon.com/";
        icon = "brave-browser";
        terminal = false;
        categories = [
          "Network"
          "WebBrowser"
        ];
      };
    };
  };
}
