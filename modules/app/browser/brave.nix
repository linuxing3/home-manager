{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.features.home;

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

  braveKeybindingsData = {
    managed_at = "2026-09-17";
    description = "Declarative keyboard shortcuts and keybindings for Brave Browser";

    # Custom accelerator keybindings that differ from default Chromium/Brave shortcuts
    customized_accelerators = [
      {
        command_id = 34014;
        command_name = "IDC_NEW_TAB";
        category = "Tab Management";
        description = "Open new tab";
        keys = [ "AppNew" "Control+Shift+KeyT" ];
        default_keys = [ "AppNew" "Control+KeyT" ];
      }
      {
        command_id = 34015;
        command_name = "IDC_CLOSE_TAB";
        category = "Tab Management";
        description = "Close active tab";
        keys = [ "AppClose" "Control+Shift+Backspace" ];
        default_keys = [ "Control+KeyW" "Control+F4" "AppClose" ];
      }
      {
        command_id = 34016;
        command_name = "IDC_SELECT_NEXT_TAB";
        category = "Tab Navigation";
        description = "Select next tab (Vim-style Right: Ctrl+Shift+L or Ctrl+\\)";
        keys = [ "Control+Backslash" "Control+Shift+KeyL" ];
        default_keys = [ "Control+Tab" "Control+PageDown" ];
      }
      {
        command_id = 34017;
        command_name = "IDC_SELECT_PREVIOUS_TAB";
        category = "Tab Navigation";
        description = "Select previous tab (Vim-style Left: Ctrl+Shift+H or Ctrl+Shift+\\)";
        keys = [ "Control+Shift+Backslash" "Control+Shift+KeyH" ];
        default_keys = [ "Control+Shift+Tab" "Control+PageUp" ];
      }
      {
        command_id = 34028;
        command_name = "IDC_RESTORE_TAB";
        category = "Tab Management";
        description = "Reopen last closed tab";
        keys = [ "Control+Shift+Enter" ];
        default_keys = [ "Control+Shift+KeyT" ];
      }
      {
        command_id = 34032;
        command_name = "IDC_MOVE_TAB_NEXT";
        category = "Tab Navigation";
        description = "Move active tab right (Vim-style: Ctrl+Alt+L or Ctrl+Shift+PageDown)";
        keys = [ "Control+Shift+PageDown" "Control+Alt+KeyL" ];
        default_keys = [ "Control+Shift+PageDown" ];
      }
      {
        command_id = 34033;
        command_name = "IDC_MOVE_TAB_PREVIOUS";
        category = "Tab Navigation";
        description = "Move active tab left (Vim-style: Ctrl+Alt+H or Ctrl+Shift+PageUp)";
        keys = [ "Control+Shift+PageUp" "Control+Alt+KeyH" ];
        default_keys = [ "Control+Shift+PageUp" ];
      }
      {
        command_id = 34057;
        command_name = "IDC_PASTE_AND_MATCH_STYLE";
        category = "Clipboard";
        description = "Paste as plain text / match style";
        keys = [ "Control+Shift+KeyV" ];
        default_keys = [ ];
      }
      {
        command_id = 34061;
        command_name = "IDC_TOGGLE_VERTICAL_TABS_COLLAPSE";
        category = "Tabs UI";
        description = "Vertical tabs collapse toggle (disabled)";
        keys = [ ];
        default_keys = [ ];
      }
      {
        command_id = 34102;
        command_name = "IDC_FOCUS_NEXT_TAB_GROUP";
        category = "Tab Groups";
        description = "Focus next tab group";
        keys = [ "Alt+Shift+Period" ];
        default_keys = [ "Alt+Shift+KeyX" ];
      }
      {
        command_id = 34103;
        command_name = "IDC_FOCUS_PREV_TAB_GROUP";
        category = "Tab Groups";
        description = "Focus previous tab group";
        keys = [ "Alt+Shift+Comma" ];
        default_keys = [ "Alt+Shift+KeyZ" ];
      }
      {
        command_id = 34104;
        command_name = "IDC_CLOSE_TAB_GROUP";
        category = "Tab Groups";
        description = "Close active tab group";
        keys = [ "Alt+Shift+KeyX" ];
        default_keys = [ "Alt+Shift+KeyW" ];
      }
      {
        command_id = 35022;
        command_name = "IDC_WINDOW_CLOSE_TABS_TO_RIGHT";
        category = "Tab Management";
        description = "Close all tabs to the right";
        keys = [ "Control+Shift+BracketRight" ];
        default_keys = [ ];
      }
      {
        command_id = 35023;
        command_name = "IDC_WINDOW_CLOSE_OTHER_TABS";
        category = "Tab Management";
        description = "Close other tabs";
        keys = [ "Control+Alt+KeyO" ];
        default_keys = [ ];
      }
      {
        command_id = 52500;
        command_name = "IDC_TAB_SEARCH";
        category = "Tab Navigation";
        description = "Search open tabs";
        keys = [ "Control+Shift+KeyK" ];
        default_keys = [ "Control+Shift+KeyA" ];
      }
      {
        command_id = 56041;
        command_name = "IDC_TOGGLE_TAB_MUTE";
        category = "Media";
        description = "Toggle tab audio mute (disabled)";
        keys = [ ];
        default_keys = [ "Control+KeyM" ];
      }
      {
        command_id = 56210;
        command_name = "IDC_WINDOW_CLOSE_TABS_TO_LEFT";
        category = "Tab Management";
        description = "Close all tabs to the left";
        keys = [ "Control+Shift+BracketLeft" ];
        default_keys = [ ];
      }
      {
        command_id = 56212;
        command_name = "IDC_WINDOW_ADD_ALL_TABS_TO_NEW_GROUP";
        category = "Tab Groups";
        description = "Add all tabs to a new group";
        keys = [ "Alt+Shift+Digit8" ];
        default_keys = [ ];
      }
      {
        command_id = 56301;
        command_name = "IDC_COMMANDER";
        category = "Quick Commands";
        description = "Brave Quick Commands / Commander palette";
        keys = [ "Control+Space" ];
        default_keys = [ "Control+Space" ];
      }
      {
        command_id = 56305;
        command_name = "IDC_WINDOW_UNGROUP_ALL_TABS";
        category = "Tab Groups";
        description = "Ungroup all tabs";
        keys = [ "Alt+Shift+Digit7" ];
        default_keys = [ ];
      }
      {
        command_id = 56306;
        command_name = "IDC_WINDOW_NAME_GROUP";
        category = "Tab Groups";
        description = "Name active tab group";
        keys = [ "Alt+Shift+KeyM" ];
        default_keys = [ ];
      }
      {
        command_id = 56311;
        command_name = "IDC_WINDOW_CLOSE_GROUP";
        category = "Tab Groups";
        description = "Close tab group";
        keys = [ "Alt+Shift+KeyW" ];
        default_keys = [ ];
      }
      {
        command_id = 56325;
        command_name = "IDC_NEW_SPLIT_VIEW";
        category = "Split View & Tiling";
        description = "Open new split view";
        keys = [ "Control+Shift+Slash" ];
        default_keys = [ ];
      }
      {
        command_id = 56326;
        command_name = "IDC_TILE_TABS";
        category = "Split View & Tiling";
        description = "Tile tabs in split view";
        keys = [ "Control+Shift+Digit5" ];
        default_keys = [ ];
      }
      {
        command_id = 56327;
        command_name = "IDC_BREAK_TILE";
        category = "Split View & Tiling";
        description = "Break tab tile / untile split view";
        keys = [ "Control+Shift+Digit6" ];
        default_keys = [ ];
      }
    ];

    # Extension commands configured in Brave
    extension_commands = {
      "linux:Alt+Shift+H" = {
        command_name = "toggle_highlighter";
        extension = "cnjifjpddelmedmihgijeibhnjfabmlf";
        extension_name = "Obsidian Web Clipper";
        description = "Toggle highlighter in web clipper";
        global = false;
      };
      "linux:Alt+Shift+O" = {
        command_name = "quick_clip";
        extension = "cnjifjpddelmedmihgijeibhnjfabmlf";
        extension_name = "Obsidian Web Clipper";
        description = "Quick clip current page to Obsidian";
        global = false;
      };
      "linux:Ctrl+Shift+1" = {
        command_name = "capture-full";
        extension = "pliibjocnfmkagafnbkfcimonlnlpghj";
        extension_name = "ClickUp";
        description = "Capture full page screenshot";
        global = false;
      };
      "linux:Ctrl+Shift+2" = {
        command_name = "capture-area";
        extension = "pliibjocnfmkagafnbkfcimonlnlpghj";
        extension_name = "ClickUp";
        description = "Capture area screenshot";
        global = false;
      };
      "linux:Ctrl+Shift+9" = {
        command_name = "generate_password";
        extension = "nngceckbapebfimnlniiiahkandclblb";
        extension_name = "Bitwarden Password Manager";
        description = "Generate secure password";
        global = false;
      };
      "linux:Ctrl+Shift+Period" = {
        command_name = "_execute_action";
        extension = "hehggadaopoacecdllhhajmbjkdcmajg";
        extension_name = "ChatGPT";
        description = "Open ChatGPT side panel / extension action";
        global = false;
      };
      "linux:Ctrl+Shift+U" = {
        command_name = "_execute_action";
        extension = "nngceckbapebfimnlniiiahkandclblb";
        extension_name = "Bitwarden Password Manager";
        description = "Bitwarden autofill login / vault action";
        global = false;
      };
    };

    # Window manager and desktop environment shortcuts targeting Brave
    window_manager_shortcuts = [
      {
        key = "Super+G";
        action = "Launch Brave with CDP remote debugging port 9222";
        command = "brave --remote-debugging-port=9222 --remote-allow-origins=* --profile-directory=Default";
        configured_in = [
          "modules/shared/oxwm/config.lua"
          "modules/wm/dwm/config.h"
          "modules/wm/xmonad/xmonad.hs"
        ];
      }
    ];

    # Vimium passthrough exclusions in Brave
    vimium_exclusions = [
      {
        pattern = "https?://mail.google.com/*";
        description = "Google Mail (use native Gmail shortcuts)";
      }
      {
        pattern = "https?://*.efwmcstyle.ccwu.cc/vnc.html";
        description = "noVNC desktop sessions (passthrough all keys)";
      }
    ];

    # Full dictionary of Brave accelerators (86 entries)
    accelerators = {
      "33000" = [ "BrowserBack" "Alt+ArrowLeft" "AltGr+ArrowLeft" ];
      "33001" = [ "BrowserForward" "Alt+ArrowRight" "AltGr+ArrowRight" ];
      "33002" = [ "Control+KeyR" "F5" "BrowserRefresh" ];
      "33003" = [ "BrowserHome" "Alt+Home" ];
      "33007" = [ "Control+Shift+KeyR" "Control+F5" "Shift+F5" "Control+BrowserRefresh" "Shift+BrowserRefresh" ];
      "34000" = [ "Control+KeyN" ];
      "34001" = [ "Control+Shift+KeyN" ];
      "34012" = [ "Control+Shift+KeyW" "Alt+F4" ];
      "34014" = [ "AppNew" "Control+Shift+KeyT" ];
      "34015" = [ "AppClose" "Control+Shift+Backspace" ];
      "34016" = [ "Control+Backslash" "Control+Shift+KeyL" ];
      "34017" = [ "Control+Shift+Backslash" "Control+Shift+KeyH" ];
      "34018" = [ "Control+Digit1" "Control+Numpad1" "Alt+Digit1" "Alt+Numpad1" ];
      "34019" = [ "Control+Digit2" "Control+Numpad2" "Alt+Digit2" "Alt+Numpad2" ];
      "34020" = [ "Control+Digit3" "Control+Numpad3" "Alt+Digit3" "Alt+Numpad3" ];
      "34021" = [ "Control+Digit4" "Control+Numpad4" "Alt+Digit4" "Alt+Numpad4" ];
      "34022" = [ "Control+Digit5" "Control+Numpad5" "Alt+Digit5" "Alt+Numpad5" ];
      "34023" = [ "Control+Digit6" "Control+Numpad6" "Alt+Digit6" "Alt+Numpad6" ];
      "34024" = [ "Control+Digit7" "Control+Numpad7" "Alt+Digit7" "Alt+Numpad7" ];
      "34025" = [ "Control+Digit8" "Control+Numpad8" "Alt+Digit8" "Alt+Numpad8" ];
      "34026" = [ "Control+Digit9" "Control+Numpad9" "Alt+Digit9" "Alt+Numpad9" ];
      "34028" = [ "Control+Shift+Enter" ];
      "34030" = [ "F11" ];
      "34032" = [ "Control+Shift+PageDown" "Control+Alt+KeyL" ];
      "34033" = [ "Control+Shift+PageUp" "Control+Alt+KeyH" ];
      "34057" = [ "Control+Shift+KeyV" ];
      "34061" = [ ];
      "34100" = [ "Alt+Shift+KeyC" ];
      "34101" = [ "Alt+Shift+KeyP" ];
      "34102" = [ "Alt+Shift+Period" ];
      "34103" = [ "Alt+Shift+Comma" ];
      "34104" = [ "Alt+Shift+KeyX" ];
      "35000" = [ "Control+KeyD" ];
      "35001" = [ "Control+Shift+KeyD" ];
      "35002" = [ "Control+KeyU" ];
      "35003" = [ "Control+KeyP" ];
      "35004" = [ "Control+KeyS" ];
      "35007" = [ "Control+Shift+KeyP" ];
      "35022" = [ "Control+Shift+BracketRight" ];
      "35023" = [ "Control+Alt+KeyO" ];
      "35031" = [ "Control+Shift+KeyS" ];
      "37000" = [ "Control+KeyF" ];
      "37001" = [ "Control+KeyG" "F3" ];
      "37002" = [ "Control+Shift+KeyG" "Shift+F3" ];
      "37003" = [ "Escape" ];
      "38001" = [ "Control+Equal" "Control+NumpadAdd" "Control+Shift+Equal" ];
      "38002" = [ "Control+Digit0" "Control+Numpad0" ];
      "38003" = [ "Control+Minus" "Control+NumpadSubtract" "Control+Shift+Minus" ];
      "39000" = [ "Alt+Shift+KeyT" ];
      "39001" = [ "Control+KeyL" "Alt+KeyD" ];
      "39002" = [ "BrowserSearch" "Control+KeyE" "Control+KeyK" ];
      "39003" = [ "F10" "AltGr" "Alt" ];
      "39004" = [ "F6" ];
      "39005" = [ "Shift+F6" ];
      "39006" = [ "Alt+Shift+KeyB" ];
      "39007" = [ "Alt+Shift+KeyA" ];
      "39009" = [ "Control+F6" ];
      "40000" = [ "Control+KeyO" ];
      "40004" = [ "Control+Shift+KeyI" ];
      "40005" = [ "Control+Shift+KeyJ" ];
      "40009" = [ "BrowserFavorites" "Control+Shift+KeyB" ];
      "40010" = [ "Control+KeyH" ];
      "40011" = [ "Control+Shift+KeyO" ];
      "40012" = [ "Control+KeyJ" ];
      "40013" = [ "Control+Shift+Delete" ];
      "40019" = [ "F1" ];
      "40021" = [ "Alt+KeyE" "Alt+KeyF" ];
      "40023" = [ "Control+Shift+KeyC" ];
      "40134" = [ "Control+Shift+KeyM" ];
      "40237" = [ "F12" ];
      "40260" = [ "F7" ];
      "40286" = [ "Shift+Escape" ];
      "40303" = [ "Alt+Shift+KeyR" ];
      "52500" = [ "Control+Shift+KeyK" ];
      "56003" = [ "Alt+Shift+KeyN" ];
      "56041" = [ ];
      "56044" = [ "Control+KeyB" ];
      "56210" = [ "Control+Shift+BracketLeft" ];
      "56212" = [ "Alt+Shift+Digit8" ];
      "56301" = [ "Control+Space" ];
      "56305" = [ "Alt+Shift+Digit7" ];
      "56306" = [ "Alt+Shift+KeyM" ];
      "56311" = [ "Alt+Shift+KeyW" ];
      "56325" = [ "Control+Shift+Slash" ];
      "56326" = [ "Control+Shift+Digit5" ];
      "56327" = [ "Control+Shift+Digit6" ];
    };
  };

  braveShortcutsScript = pkgs.writeShellApplication {
    name = "brave-shortcuts";
    runtimeInputs = with pkgs; [ coreutils ];
    text = ''
      # Interactive selector or command line dispatcher for Brave shortcuts & keybindings
      target="''${1:-}"

      print_keybindings() {
        cat <<'EOF'
================================================================================
                    BRAVE BROWSER KEYBOARD SHORTCUTS
================================================================================

[Tab Navigation & Management (Vim-Style Navigation)]
  Ctrl+Shift+T                  New Tab (IDC_NEW_TAB)
  Ctrl+Shift+Backspace          Close Active Tab (IDC_CLOSE_TAB)
  Ctrl+\  or  Ctrl+Shift+L      Next Tab (Vim Right) (IDC_SELECT_NEXT_TAB)
  Ctrl+Shift+\  or  Ctrl+Shift+H Prev Tab (Vim Left) (IDC_SELECT_PREVIOUS_TAB)
  Ctrl+Shift+Enter              Reopen Closed Tab (IDC_RESTORE_TAB)
  Ctrl+Alt+L  or  Ctrl+Shift+PgDn Move Tab Right (IDC_MOVE_TAB_NEXT)
  Ctrl+Alt+H  or  Ctrl+Shift+PgUp Move Tab Left (IDC_MOVE_TAB_PREVIOUS)
  Ctrl+Shift+[                  Close Tabs to the Left (IDC_WINDOW_CLOSE_TABS_TO_LEFT)
  Ctrl+Shift+]                  Close Tabs to the Right (IDC_WINDOW_CLOSE_TABS_TO_RIGHT)
  Ctrl+Alt+O                    Close Other Tabs (IDC_WINDOW_CLOSE_OTHER_TABS)
  Ctrl+Shift+K                  Search Tabs (IDC_TAB_SEARCH)
  Ctrl+1 .. Ctrl+9              Switch to Tab 1-8 / Last Tab

[Split View & Tab Groups]
  Ctrl+Space                    Brave Commander / Quick Commands (IDC_COMMANDER)
  Ctrl+Shift+/                  New Split View (IDC_NEW_SPLIT_VIEW)
  Ctrl+Shift+5                  Tile Tabs in Split View (IDC_TILE_TABS)
  Ctrl+Shift+6                  Break Tile / Untile (IDC_BREAK_TILE)
  Alt+Shift+8                   Add All Tabs to New Group
  Alt+Shift+7                   Ungroup All Tabs
  Alt+Shift+M                   Name Active Tab Group
  Alt+Shift+W                   Close Active Tab Group
  Alt+Shift+.                   Focus Next Tab Group
  Alt+Shift+,                   Focus Previous Tab Group
  Alt+Shift+P                   Create New Tab Group
  Alt+Shift+C                   Add New Tab to Group

[Browser & UI Controls]
  Ctrl+B                        Toggle Brave Sidebar (IDC_TOGGLE_SIDEBAR)
  Ctrl+Shift+V                  Paste and Match Style (Plain Text)
  Ctrl+L  or  Alt+D             Focus Address Bar / Omnibox
  Ctrl+Shift+B                  Toggle Bookmarks Bar
  Ctrl+Shift+I  or  F12         Developer Tools
  Ctrl+Shift+J                  Developer Tools Console
  Ctrl+Shift+C                  Inspect Element with DevTools
  Shift+Escape                  Task Manager
  Alt+Shift+N                   New Private Window with Tor

[Extension Shortcuts]
  Alt+Shift+O                   Obsidian Web Clipper: Quick Clip
  Alt+Shift+H                   Obsidian Web Clipper: Toggle Highlighter
  Ctrl+Shift+1                  ClickUp: Capture Full Page Screenshot
  Ctrl+Shift+2                  ClickUp: Capture Area Screenshot
  Ctrl+Shift+9                  Bitwarden: Generate Password
  Ctrl+Shift+U                  Bitwarden: Autofill Login / Vault
  Ctrl+Shift+.                  ChatGPT: Open Side Panel / Extension Action

[Window Manager Integration]
  Super+G                       Launch Brave with CDP Debugging Port 9222
                                (defined in oxwm, dwm, and xmonad)
================================================================================
EOF
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
in
{
  options.my.features.home.brave = lib.mkEnableOption "Enable Brave browser module with managed shortcuts and keybindings";

  config = lib.mkIf cfg.brave {
    home.packages = [
      pkgs.brave
      braveShortcutsScript
    ];

    # Full JSON snapshot of all Brave web shortcuts, top sites, and omnibox shortcuts
    xdg.dataFile."brave/shortcuts.json".text = builtins.toJSON braveShortcutsData;

    # Full declarative keybindings snapshot (accelerators, extension commands, descriptions)
    xdg.dataFile."brave/keybindings.json".text = builtins.toJSON braveKeybindingsData;

    # Declaratively sync and preserve Brave accelerators & extension keybindings in profile
    home.activation.mergeBravePreferences = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
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
