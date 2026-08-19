---
name: repair-herdr-hx
description: Use when Herdr prefix+m does not open the Helix sidebar, linuxing3.herdr-hx.toggle is missing, or herdr-nvim is installed from the default Neovim branch instead of herdr-hx.
---

# Repair Herdr Helix sidebar (prefix+m)

`prefix+m` (`ctrl+b` then `m`) invokes `linuxing3.herdr-hx.toggle`. That action comes from the **`herdr-hx` branch** of `linuxing3/herdr-nvim`, not from default `herdr-nvim`.

Default-branch install registers `chmarax.herdr-nvim`. `prefix+m` then does nothing because `linuxing3.herdr-hx` is absent.

## Diagnose

```sh
herdr plugin list
herdr plugin action list | python3 -c 'import json,sys; d=json.load(sys.stdin); print([a["plugin_id"]+"."+a["action_id"] for a in d["result"]["actions"] if "hx" in a["plugin_id"] or "nvim" in a["plugin_id"]])'
command -v hx
cat ~/.config/herdr-hx/config.toml
```

Failure is `chmarax.herdr-nvim` listed, `linuxing3.herdr-hx.toggle` missing, or `hx_bin` not pointing at a working Helix.

## Runtime repair

```sh
herdr plugin uninstall chmarax.herdr-nvim
export CARGO_HOME="${CARGO_HOME:-$HOME/.cache/herdr-plugin-cargo}"
nix shell nixpkgs#rustc nixpkgs#cargo nixpkgs#gcc nixpkgs#pkg-config -c \
  herdr plugin install linuxing3/herdr-nvim --ref herdr-hx --yes
herdr plugin list
```

Require `linuxing3.herdr-hx (herdr-hx) enabled [github:linuxing3/herdr-nvim@herdr-hx]`. Cargo is required; this branch has no aarch64 prebuild. Point `hx_bin` at Nix Helix if plugin PATH cannot find `hx`:

```toml
[sidebar]
hx_bin = "/home/Designers/.nix-profile/bin/hx"
```

Reload Herdr config or restart the session, then `ctrl+b` `m`.

## Persist

Keep `{ source = "linuxing3/herdr-nvim"; ref = "herdr-hx"; }` in `modules/app/ai-agents/herdr/files/plugins.json`. Plugin sync must pass `--ref` and replace a same-repo Neovim checkout. Keep `prefix+m` as `linuxing3.herdr-hx.toggle` in `modules/app/ai-agents/herdr/files/config.toml`. Keep `xdg.configFile."herdr-hx/config.toml"` with `hx_bin = lib.getExe pkgs.helix` in `modules/app/ai-agents/herdr/default.nix`.

Do not install default `linuxing3/herdr-nvim` for this binding.

## Verify

```sh
herdr plugin list | grep linuxing3.herdr-hx
test -x "$(python3 -c 'import json,sys,pathlib; d=json.load(sys.stdin); p=[x for x in d["result"]["plugins"] if x["plugin_id"]=="linuxing3.herdr-hx"][0]; print(p["source"]["managed_path"]+"/bin/herdr-hx")' <<< "$(herdr plugin list --json)")"
```

Require the plugin enabled, `herdr-hx` executable present, and `hx` runnable. In a Herdr session, `prefix+m` must open a Helix sidebar.
