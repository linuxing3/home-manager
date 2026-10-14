# Brave keybindings backup

- Exported: `2026-09-18T23:53:45`
- Profile: `/home/Designers/.config/BraveSoftware/Brave-Browser/Default`
- Custom accelerator entries: **87**
- Default accelerator entries: **85**
- Differs from defaults: **46**
- Extension command index entries: **7**

## Restoring

1. Quit Brave completely.
2. Merge `restore-slices.json` into `Default/Preferences`:
   - `brave.accelerators`
   - `brave.default_accelerators` (optional reference)
   - `extensions.commands`
3. Restart Brave and verify at `brave://settings/system/system-shortcuts` (or Settings → System → Shortcuts).

## Changed from defaults

| ID | Command | Default | Current |
| --- | --- | --- | --- |
| `33007` | ReloadBypassingCache | `Control+Shift+KeyR`, `Control+F5`, `Shift+F5`, `Control+BrowserRefresh`, `Shift+BrowserRefresh` | `Control+Shift+KeyR`, `Control+F5`, `Control+BrowserRefresh`, `Shift+BrowserRefresh` |
| `34012` | Exit | `Control+Shift+KeyW`, `Alt+F4` | `Alt+F4` |
| `34014` | NewTab | `AppNew`, `Control+KeyT` | `AppNew`, `Alt+KeyT` |
| `34015` | CloseTab | `Control+KeyW`, `Control+F4`, `AppClose` | `AppClose`, `Alt+KeyW` |
| `34016` | RestoreTab | `Control+Tab`, `Control+PageDown` | `Alt+KeyL` |
| `34017` | SelectNextTab | `Control+Shift+Tab`, `Control+PageUp` | `Alt+Shift+ArrowLeft`, `Alt+KeyH` |
| `34018` | SelectTab0 | `Control+Digit1`, `Control+Numpad1`, `Alt+Digit1`, `Alt+Numpad1` | `Alt+Digit1`, `Alt+Numpad1` |
| `34019` | SelectTab1 | `Control+Digit2`, `Control+Numpad2`, `Alt+Digit2`, `Alt+Numpad2` | `Alt+Digit2`, `Alt+Numpad2` |
| `34020` | SelectTab2 | `Control+Digit3`, `Control+Numpad3`, `Alt+Digit3`, `Alt+Numpad3` | `Alt+Digit3`, `Alt+Numpad3` |
| `34021` | SelectTab3 | `Control+Digit4`, `Control+Numpad4`, `Alt+Digit4`, `Alt+Numpad4` | `Alt+Digit4`, `Alt+Numpad4` |
| `34022` | SelectTab4 | `Control+Digit5`, `Control+Numpad5`, `Alt+Digit5`, `Alt+Numpad5` | `Alt+Digit5`, `Alt+Numpad5` |
| `34023` | SelectTab5 | `Control+Digit6`, `Control+Numpad6`, `Alt+Digit6`, `Alt+Numpad6` | `Alt+Digit6`, `Alt+Numpad6` |
| `34024` | SelectTab6 | `Control+Digit7`, `Control+Numpad7`, `Alt+Digit7`, `Alt+Numpad7` | `Alt+Digit7`, `Alt+Numpad7` |
| `34025` | SelectTab7 | `Control+Digit8`, `Control+Numpad8`, `Alt+Digit8`, `Alt+Numpad8` | `Alt+Digit8`, `Alt+Numpad8` |
| `34026` | SelectLastTab | `Control+Digit9`, `Control+Numpad9`, `Alt+Digit9`, `Alt+Numpad9` | `Alt+Digit9`, `Alt+Numpad9` |
| `34028` | DuplicateTab | `Control+Shift+KeyT` | `Alt+Shift+Enter` |
| `34057` | MuteTab | _(cleared)_ | `Alt+KeyV` |
| `34061` | PinTab | _(unset)_ | `Alt+Shift+KeyC` |
| `34100` | CloseWindow | `Alt+Shift+KeyC` | _(cleared)_ |
| `34102` | MoveTabToNewWindow | `Alt+Shift+KeyX` | `Alt+Shift+Period` |
| `34103` | SearchTabs | `Alt+Shift+KeyZ` | `Alt+Shift+Comma` |
| `34104` | CloseOtherTabs | `Alt+Shift+KeyW` | _(cleared)_ |
| `35022` | FocusBookmarksToolbar | _(cleared)_ | `Alt+Shift+BracketRight` |
| `38001` | ZoomPlus | `Control+Equal`, `Control+NumpadAdd`, `Control+Shift+Equal` | `Control+Equal` |
| `38002` | ZoomNormal | `Control+Digit0`, `Control+Numpad0` | `Control+Digit0` |
| `38003` | ZoomMinus | `Control+Minus`, `Control+NumpadSubtract`, `Control+Shift+Minus` | `Control+Minus` |
| `39000` | FocusLocation | `Alt+Shift+KeyT` | `Control+KeyT` |
| `39001` | FocusToolbar | `Control+KeyL`, `Alt+KeyD` | `Control+KeyL` |
| `39003` | FocusMenuBar | `F10`, `Alt`, `Alt`, `AltGr` | `F10` |
| `39006` | FocusWebContentsPane | `Alt+Shift+KeyB` | _(cleared)_ |
| `40000` | OpenFile | `Control+KeyO` | `Alt+KeyO` |
| `40009` | ShowBookmarks | `BrowserFavorites`, `Control+Shift+KeyB` | `BrowserFavorites`, `Alt+Shift+KeyB` |
| `40013` | ClearBrowsingData | `Control+Shift+Delete` | `Alt+Shift+Delete` |
| `40019` | Options | `F1` | _(cleared)_ |
| `40022` | EditSearchEngines | _(unset)_ | `Alt+Shift+KeyE` |
| `52500` | Command52500 | `Control+Shift+KeyA` | `Alt+Shift+KeyK` |
| `56041` | Command56041 | `Control+KeyM` | _(cleared)_ |
| `56210` | Command56210 | _(cleared)_ | `Alt+Shift+BracketLeft` |
| `56212` | Command56212 | _(cleared)_ | `Alt+Shift+Digit8` |
| `56301` | Command56301 | `Control+Space` | `Alt+Shift+Space` |
| `56305` | Command56305 | _(cleared)_ | `Alt+Shift+Digit7` |
| `56306` | Command56306 | _(cleared)_ | `Alt+Shift+KeyM` |
| `56311` | Command56311 | _(cleared)_ | `Alt+Shift+KeyW` |
| `56325` | Command56325 | _(cleared)_ | `Alt+Slash` |
| `56326` | Command56326 | _(cleared)_ | `Alt+Shift+Digit5` |
| `56327` | Command56327 | _(cleared)_ | `Alt+Shift+Digit6` |

## All custom Brave accelerators

| ID | Command | Shortcuts |
| --- | --- | --- |
| `33000` | Back | `BrowserBack`, `Alt+ArrowLeft`, `AltGr+ArrowLeft` |
| `33001` | Forward | `BrowserForward`, `Alt+ArrowRight`, `AltGr+ArrowRight` |
| `33002` | Reload | `Control+KeyR`, `F5`, `BrowserRefresh` |
| `33003` | Home | `BrowserHome`, `Alt+Home` |
| `33007` | ReloadBypassingCache | `Control+Shift+KeyR`, `Control+F5`, `Control+BrowserRefresh`, `Shift+BrowserRefresh` |
| `34000` | NewWindow | `Control+KeyN` |
| `34001` | NewIncognitoWindow | `Control+Shift+KeyN` |
| `34012` | Exit | `Alt+F4` |
| `34014` | NewTab | `AppNew`, `Alt+KeyT` |
| `34015` | CloseTab | `AppClose`, `Alt+KeyW` |
| `34016` | RestoreTab | `Alt+KeyL` |
| `34017` | SelectNextTab | `Alt+Shift+ArrowLeft`, `Alt+KeyH` |
| `34018` | SelectTab0 | `Alt+Digit1`, `Alt+Numpad1` |
| `34019` | SelectTab1 | `Alt+Digit2`, `Alt+Numpad2` |
| `34020` | SelectTab2 | `Alt+Digit3`, `Alt+Numpad3` |
| `34021` | SelectTab3 | `Alt+Digit4`, `Alt+Numpad4` |
| `34022` | SelectTab4 | `Alt+Digit5`, `Alt+Numpad5` |
| `34023` | SelectTab5 | `Alt+Digit6`, `Alt+Numpad6` |
| `34024` | SelectTab6 | `Alt+Digit7`, `Alt+Numpad7` |
| `34025` | SelectTab7 | `Alt+Digit8`, `Alt+Numpad8` |
| `34026` | SelectLastTab | `Alt+Digit9`, `Alt+Numpad9` |
| `34028` | DuplicateTab | `Alt+Shift+Enter` |
| `34030` | Fullscreen | `F11` |
| `34032` | MoveTabNext | `Control+Shift+PageDown` |
| `34033` | MoveTabPrevious | `Control+Shift+PageUp` |
| `34057` | MuteTab | `Alt+KeyV` |
| `34061` | PinTab | `Alt+Shift+KeyC` |
| `34100` | CloseWindow | _(cleared)_ |
| `34101` | SelectPreviousTab | `Alt+Shift+KeyP` |
| `34102` | MoveTabToNewWindow | `Alt+Shift+Period` |
| `34103` | SearchTabs | `Alt+Shift+Comma` |
| `34104` | CloseOtherTabs | _(cleared)_ |
| `35000` | BookmarkThisTab | `Control+KeyD` |
| `35001` | BookmarkAllTabs | `Control+Shift+KeyD` |
| `35002` | ViewSource | `Control+KeyU` |
| `35003` | Print | `Control+KeyP` |
| `35004` | SavePage | `Control+KeyS` |
| `35007` | ShowBookmarkBar | `Control+Shift+KeyP` |
| `35022` | FocusBookmarksToolbar | `Alt+Shift+BracketRight` |
| `35023` | ShowBookmarksSidePanel | _(cleared)_ |
| `35031` | SaveAndShare | `Control+Shift+KeyS` |
| `37000` | Find | `Control+KeyF` |
| `37001` | FindNext | `Control+KeyG`, `F3` |
| `37002` | FindPrevious | `Control+Shift+KeyG`, `Shift+F3` |
| `37003` | Stop | `Escape` |
| `38001` | ZoomPlus | `Control+Equal` |
| `38002` | ZoomNormal | `Control+Digit0` |
| `38003` | ZoomMinus | `Control+Minus` |
| `39000` | FocusLocation | `Control+KeyT` |
| `39001` | FocusToolbar | `Control+KeyL` |
| `39002` | FocusSearch | `BrowserSearch`, `Control+KeyE`, `Control+KeyK` |
| `39003` | FocusMenuBar | `F10` |
| `39004` | FocusNextPane | `F6` |
| `39005` | FocusPreviousPane | `Shift+F6` |
| `39006` | FocusWebContentsPane | _(cleared)_ |
| `39007` | ShowAppMenu | `Alt+Shift+KeyA` |
| `39009` | FocusInactivePopup | `Control+F6` |
| `40000` | OpenFile | `Alt+KeyO` |
| `40004` | DevTools | `Control+Shift+KeyI` |
| `40005` | DevToolsConsole | `Control+Shift+KeyJ` |
| `40009` | ShowBookmarks | `BrowserFavorites`, `Alt+Shift+KeyB` |
| `40010` | ShowHistory | `Control+KeyH` |
| `40011` | ShowBookmarksManager | `Control+Shift+KeyO` |
| `40012` | ShowDownloads | `Control+KeyJ` |
| `40013` | ClearBrowsingData | `Alt+Shift+Delete` |
| `40019` | Options | _(cleared)_ |
| `40021` | ShowAppMenu | `Alt+KeyE`, `Alt+KeyF` |
| `40022` | EditSearchEngines | `Alt+Shift+KeyE` |
| `40023` | DevToolsInspect | `Control+Shift+KeyC` |
| `40134` | ShowPasswordManager | `Control+Shift+KeyM` |
| `40237` | DevToolsToggle | `F12` |
| `40260` | Command40260 | `F7` |
| `40286` | Command40286 | `Shift+Escape` |
| `40303` | Command40303 | `Alt+Shift+KeyR` |
| `52500` | Command52500 | `Alt+Shift+KeyK` |
| `56003` | Command56003 | `Alt+Shift+KeyN` |
| `56041` | Command56041 | _(cleared)_ |
| `56044` | Command56044 | `Control+KeyB` |
| `56210` | Command56210 | `Alt+Shift+BracketLeft` |
| `56212` | Command56212 | `Alt+Shift+Digit8` |
| `56301` | Command56301 | `Alt+Shift+Space` |
| `56305` | Command56305 | `Alt+Shift+Digit7` |
| `56306` | Command56306 | `Alt+Shift+KeyM` |
| `56311` | Command56311 | `Alt+Shift+KeyW` |
| `56325` | Command56325 | `Alt+Slash` |
| `56326` | Command56326 | `Alt+Shift+Digit5` |
| `56327` | Command56327 | `Alt+Shift+Digit6` |

## Extension command index

| Accelerator | Binding |
| --- | --- |
| `linux:Alt+Shift+H` | `{"command_name": "toggle_highlighter", "description": "Toggle highlighter in web clipper", "extension": "cnjifjpddelmedmihgijeibhnjfabmlf", "extension_name": "Obsidian Web Clipper", "global": false}` |
| `linux:Alt+Shift+O` | `{"command_name": "quick_clip", "description": "Quick clip current page to Obsidian", "extension": "cnjifjpddelmedmihgijeibhnjfabmlf", "extension_name": "Obsidian Web Clipper", "global": false}` |
| `linux:Ctrl+Shift+1` | `{"command_name": "capture-full", "description": "Capture full page screenshot", "extension": "pliibjocnfmkagafnbkfcimonlnlpghj", "extension_name": "ClickUp", "global": false}` |
| `linux:Ctrl+Shift+2` | `{"command_name": "capture-area", "description": "Capture area screenshot", "extension": "pliibjocnfmkagafnbkfcimonlnlpghj", "extension_name": "ClickUp", "global": false}` |
| `linux:Ctrl+Shift+9` | `{"command_name": "generate_password", "description": "Generate secure password", "extension": "nngceckbapebfimnlniiiahkandclblb", "extension_name": "Bitwarden Password Manager", "global": false}` |
| `linux:Ctrl+Shift+Period` | `{"command_name": "_execute_action", "description": "Open ChatGPT side panel / extension action", "extension": "hehggadaopoacecdllhhajmbjkdcmajg", "extension_name": "ChatGPT", "global": false}` |
| `linux:Ctrl+Shift+U` | `{"command_name": "_execute_action", "description": "Bitwarden autofill login / vault action", "extension": "nngceckbapebfimnlniiiahkandclblb", "extension_name": "Bitwarden Password Manager", "global": false}` |

## Per-extension command bindings

### Bitwarden Password Manager (`nngceckbapebfimnlniiiahkandclblb`)

| Command | Config |
| --- | --- |
| `_execute_action` | `{"suggested_key": "Ctrl+Shift+U", "was_assigned": true}` |
| `autofill_card` | `{"suggested_key": "", "was_assigned": true}` |
| `autofill_identity` | `{"suggested_key": "", "was_assigned": true}` |
| `autofill_login` | `{"suggested_key": "Ctrl+Shift+L"}` |
| `generate_password` | `{"suggested_key": "Ctrl+Shift+9", "was_assigned": true}` |
| `lock_vault` | `{"suggested_key": "", "was_assigned": true}` |

### ChatGPT (`hehggadaopoacecdllhhajmbjkdcmajg`)

| Command | Config |
| --- | --- |
| `_execute_action` | `{"suggested_key": "Ctrl+Shift+Period", "was_assigned": true}` |
| `open-codex-side-panel` | `{"suggested_key": "", "was_assigned": true}` |

### ClickUp: Tasks, Screenshots, Email, Time (`pliibjocnfmkagafnbkfcimonlnlpghj`)

| Command | Config |
| --- | --- |
| `_execute_action` | `{"was_assigned": true}` |
| `capture-area` | `{"suggested_key": "Ctrl+Shift+2", "was_assigned": true}` |
| `capture-full` | `{"suggested_key": "Ctrl+Shift+1", "was_assigned": true}` |
| `notepad` | `{"suggested_key": "Ctrl+Shift+N"}` |

### DS Amazon Quick View (`jkompbllimaoekaogchhkmkdogpkhojg`)

| Command | Config |
| --- | --- |
| `_execute_action` | `{"was_assigned": true}` |

### Obsidian Web Clipper (`cnjifjpddelmedmihgijeibhnjfabmlf`)

| Command | Config |
| --- | --- |
| `_execute_action` | `{"suggested_key": "Ctrl+Shift+O"}` |
| `quick_clip` | `{"suggested_key": "Alt+Shift+O", "was_assigned": true}` |
| `toggle_highlighter` | `{"suggested_key": "Alt+Shift+H", "was_assigned": true}` |
| `toggle_reader` | `{"suggested_key": "Alt+Shift+R"}` |

### pgnmfdgbcbapodabmeennmhejdnleaip (`pgnmfdgbcbapodabmeennmhejdnleaip`)

| Command | Config |
| --- | --- |
| `_execute_action` | `{"was_assigned": true}` |

### vidIQ Vision for YouTube (`pachckjkecffpdphbpmfolblodfkgbhl`)

| Command | Config |
| --- | --- |
| `_execute_action` | `{"was_assigned": true}` |

### Vimium (`dbepggeogbaibhgnhhndojpepiihcmeb`)

| Command | Config |
| --- | --- |
| `_execute_action` | `{"was_assigned": true}` |

### YouTube to NotebookLM - YouTube to Gemini Notebook (`kobncfkmjelbefaoohoblamnbackjggk`)

| Command | Config |
| --- | --- |
| `_execute_action` | `{"was_assigned": true}` |

### ZAPI FLOW (`debadkiomlbdambamdpdlgdkgnedcjil`)

| Command | Config |
| --- | --- |
| `_execute_action` | `{"was_assigned": true}` |

