# nnn Herdr Open Command Picker Design

## Goal

When opening an nnn-synced Herdr Plus project with `ctrl+b` then up-arrow,
choose the command for that open: `cursor-agent`, `pi`, `codex`, `hx`, or
shell. The choice is made every time. It is not stored per bookmark.

## Architecture

`ctrl+b` + up-arrow and Herdr Plus stay as they are. nnn bookmarks still
sync to one Herdr Plus project file each. The generated tab command changes
from hardcoded `cursor-agent` to a Home Manager wrapper, `nnn-herdr-open`.
That wrapper is the command picker. It `exec`s the chosen command in the
bookmark directory Herdr Plus already set as `working_dir`.

Non-nnn projects such as `grok-sim` are not rewritten by the sync and stay
unchanged.

## Components

### `nnn-herdr-open`

A `writeShellApplication` in `modules/tui/nnn-herdr-sync.nix`, installed on
the user profile PATH next to `nnn-herdr-sync`.

- Lists exactly five entries in `fzf`: `cursor-agent`, `pi`, `codex`, `hx`,
  and `shell`.
- The five names are hardcoded in the script.
- `fzf` comes from the wrapper `runtimeInputs`, not from the pane PATH.
- A selection `exec`s that command (`shell` means `${SHELL:-bash}`).
- Esc or an empty selection starts `${SHELL:-bash}` in the same pane.

### Sync template

`modules/tui/sync-nnn-herdr-projects.py` `render_project` emits:

```toml
[[tabs]]
name = "open"
command = "nnn-herdr-open"
```

The next sync overwrites managed `nnn*.toml` files, same as today.

## Data flow

1. Press `ctrl+b` then up-arrow. Herdr Plus shows the project fuzzy list,
   including nnn-synced bookmarks.
2. Pick a bookmark project. Herdr Plus opens a workspace rooted at that
   bookmark directory and starts the `open` tab with `nnn-herdr-open`.
3. `fzf` lists `cursor-agent`, `pi`, `codex`, `hx`, and `shell`.
4. A choice replaces the picker process with that command in the same pane.
   Esc leaves an interactive shell in the same directory.

## Error handling

- Esc or empty `fzf` selection does not close the pane; start
  `${SHELL:-bash}` in the bookmark directory.
- If the chosen binary is missing from PATH, print a short error that names
  the command, then start `${SHELL:-bash}`.
- The wrapper always has `fzf` via `runtimeInputs`.
- Malformed or stale nnn project files stay the sync's responsibility: it
  still owns `nnn*.toml` and rewrites them on the next run.

## Out of scope

- Per-bookmark stored default commands.
- Opening all five commands as tabs in one project.
- Five Herdr Plus project files per bookmark.
- Changing Herdr Plus itself or the `prefix+up` keybinding.
- Non-nnn Herdr Plus projects.

## Verification

1. Format the changed Nix file with Alejandra.
2. Run `nix flake check`.
3. Run `nnn-herdr-sync` against a temporary bookmark and projects directory
   and confirm the generated file has `command = "nnn-herdr-open"`.
4. Confirm a non-nnn project file such as `grok-sim.toml` is unchanged.
5. Confirm `nnn-herdr-open` is on PATH after Home Manager activation.
6. Dry-run the wrapper (Esc) and confirm it starts a shell.
7. After activation, open one nnn-synced project with `ctrl+b` then
   up-arrow, pick `hx`, and confirm Helix starts in that bookmark
   directory.
