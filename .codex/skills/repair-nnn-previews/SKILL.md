---
name: repair-nnn-previews
description: Use when nnn preview-tabbed cannot display PDF, DOCX, XLSX, XLS, XLSM, or ODS files; Zathura opens without PDF plugins; doxx or xleak is missing; or Home Manager reports same-content collisions for nnn/plugins/nuke or preview-tabbed.
---

# Repair nnn previews

The source of truth is `modules/tui/nnn-plugins.nix`. The work profile imports it through `modules/shell/sh.nix` and installs `doxx` and `xleak` through `modules/shell/cli-collection.nix`.

## PDF

Keep upstream `preview-tabbed`, but substitute both its Zathura availability check and launch command with `lib.getExe pkgs.zathura`. This selects the Nix wrapper that includes the PDF plugin; a bare or unwrapped Zathura executable can start successfully while failing to render PDFs.

The plugin is XEmbed/X11-only. `WAYLAND_DISPLAY` must be empty, and `tabbed`, an XEmbed-capable terminal, `file`, and `xdotool` must be available.

## Office documents

Patch upstream `nuke` before its PDF case:

- `.docx`: `${lib.getExe pkgs.doxx} --export ansi -- "$FPATH" | eval "$PAGER"`
- `.xlsx`, `.xls`, `.xlsm`, `.ods`: `${lib.getExe pkgs.xleak} "$FPATH" | eval "$PAGER"`

Use noninteractive output because `preview-tabbed` embeds `nuke` in a terminal and replaces the preview process as selections change.

## Home Manager link collision

Messages saying an existing `~/.config/nnn/plugins/nuke` or `preview-tabbed` “will be skipped since they are the same” are warnings, not a failed activation. They occur when a manual symlink already points at content Home Manager is about to own.

Verify first:

```sh
stat -c '%N' ~/.config/nnn/plugins/nuke ~/.config/nnn/plugins/preview-tabbed
readlink -f ~/.config/nnn/plugins/nuke
readlink -f ~/.config/nnn/plugins/preview-tabbed
```

If the links resolve to the generated Home Manager file tree or the expected Nix store sources, rerun the current activation; `linkGeneration` cleans and recreates managed links. Do not delete divergent user files without reviewing or backing them up.

```sh
activation=$(nix eval --raw '.#homeConfigurations.Designers.activationPackage')
"$activation/activate"
```

## Verification

```sh
nix build --no-link .#homeConfigurations.Designers.activationPackage
nuke=$(nix eval --raw '.#homeConfigurations.Designers.config.xdg.configFile."nnn/plugins/nuke".source')
PAGER=cat "$nuke" sample.docx
PAGER=cat "$nuke" sample.xlsx
```

For PDF, launch `preview-tabbed` with a dedicated FIFO, write an existing PDF path to the FIFO, and confirm the spawned command uses the wrapped Zathura with `-e <tabbed-xid>`. Restart nnn or toggle preview after activation.

See `docs/nnn-previews.md` for configuration ownership and troubleshooting details.
