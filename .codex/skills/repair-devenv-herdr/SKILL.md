---
name: repair-devenv-herdr
description: Use when herdr is missing from `nix develop`/`direnv`, devenv reports attribute 'herdr' missing, inputs.llm-agents.herdr is not found, or this UOS host cannot provide the Numtide herdr package.
---

# Repair devenv herdr

Project PATH comes from `.envrc` (`use flake`), not `devenv shell`. `herdr`
comes from `github:numtide/llm-agents.nix` as `packages.<system>.herdr`. It is
not `inputs.llm-agents.herdr`.

`flake.nix` must declare the input:

```nix
llm-agents.url = "github:numtide/llm-agents.nix";
```

`flake/devshells.nix` must bind the package output, not a root flake attribute:

```nix
{inputs, ...}: {
  perSystem = {
    system,
    pkgs,
    ...
  }: let
    llm-agents = inputs.llm-agents.packages.${system};
  in {
    devShells.default = pkgs.mkShell {
      packages = [
        llm-agents.herdr
      ];
    };
  };
}
```

CLIProxyAPI remains a Home Manager package (`my.ai.cliProxyApi`). Do not
`nix profile add` `herdr`; Home Manager already puts it on PATH via
`home.packages`. A second profile install collides on `bin/herdr`.

`devenv.nix` is optional. Keep `.envrc` as `use flake`. If someone still runs
`devenv shell` and needs herdr there, bind `inputs.llm-agents.packages.${pkgs.stdenv.system}.herdr` the same way — never `inputs.llm-agents.herdr`.

## Verify

```sh
PATH=/home/Designers/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH
nix develop --command sh -c 'command -v herdr && herdr --version'
```

Require evaluation with no `attribute 'herdr' missing`, and `herdr` on the
flake devShell. After the Nix change, `direnv allow` picks it up.

Do not print secret values while diagnosing PATH.
