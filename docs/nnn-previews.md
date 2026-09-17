# nnn previews

The work profile uses nnn’s upstream `preview-tabbed` and `nuke` plugins, patched declaratively in `modules/tui/nnn-plugins.nix`.

## Ownership

| Path | Purpose |
| --- | --- |
| `modules/tui/nnn-plugins.nix` | Builds patched `preview-tabbed` and `nuke` scripts and installs them under `~/.config/nnn/plugins` |
| `modules/shell/sh.nix` | Sets `NNN_FIFO`, `NNN_OPENER`, and the `p:preview-tabbed` plugin mapping |
| `modules/shell/cli-collection.nix` | Installs `doxx`, `xleak`, and supporting CLI tools |
| `profiles/work/packages.nix` | Installs `tabbed`, wrapped Zathura, and graphical preview tools |

## Formats

| Format | Previewer | Reason |
| --- | --- | --- |
| PDF | wrapped Zathura embedded in `tabbed` | The wrapper supplies the `pdf-mupdf` plugin and accepts `-e <XID>` |
| DOCX | `doxx --export ansi` | Rich, noninteractive terminal output suitable for the embedded preview terminal |
| XLSX, XLS, XLSM, ODS | `xleak` | Noninteractive spreadsheet rendering with sheet/table formatting |

The PDF plugin is X11-only because `preview-tabbed` uses XEmbed. It intentionally refuses Wayland.

## Activation collision warning

An activation can report that `nuke` or `preview-tabbed` is “in the way” but “will be skipped since they are the same.” This means a manually created symlink and Home Manager’s generated link resolve to identical content. Check with `stat -c '%N'` and `readlink -f`, then rerun the evaluated activation. Home Manager’s `linkGeneration` should take ownership without deleting content.

Never remove a nonidentical file blindly. Back it up or use the normal Home Manager `-b hm-bak` switch flow.

## Verification

Build the Home Manager activation package, evaluate each generated plugin source, run `nuke` against real DOCX/XLSX fixtures with `PAGER=cat`, and smoke-test a PDF through a dedicated FIFO. For PDF debugging, temporarily preserve plugin output and confirm Zathura loads an `application/pdf` plugin and reparents into the tabbed XID.

Operational skill: `.codex/skills/repair-nnn-previews/SKILL.md`.
