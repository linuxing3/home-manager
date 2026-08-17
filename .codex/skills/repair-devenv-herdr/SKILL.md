---
name: repair-devenv-herdr
description: Use when devenv reports attribute 'herdr' missing, inputs.llm-agents.herdr is not found, or direnv/devenv cannot provide the Numtide herdr package on this UOS host.
---

# Repair devenv herdr

`herdr` comes from `github:numtide/llm-agents.nix` as `packages.<system>.herdr`. It is not `inputs.llm-agents.herdr`.

`devenv.yaml` must declare the input:

```yaml
inputs:
  llm-agents:
    url: github:numtide/llm-agents.nix
```

`devenv.nix` must bind the package output, not a root flake attribute:

```nix
{pkgs, inputs, ...}: let
  llm-agents = inputs.llm-agents.packages.${pkgs.stdenv.system};
in {
  packages = [llm-agents.herdr];
}
```

Do not enable devenv overlays only to reach `pkgs.herdr` unless that overlay is actually imported. This project's `devenv.nix` keeps overlays commented out.

## Verify

```sh
PATH=/home/Designers/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH
devenv info
command -v herdr
herdr --version
```

Require evaluation with no `attribute 'herdr' missing`, and `herdr` on the devenv profile. After the Nix change, `direnv allow` or `devenv shell` picks it up.

Do not add a production flake input only to satisfy devenv. CLIProxyAPI remains a `nix profile` install from llm-agents.nix; see `uos-desktop-bootstrap`.
