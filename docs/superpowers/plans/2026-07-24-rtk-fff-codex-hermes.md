# RTK and fff-mcp Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Install pinned RTK and fff-mcp binaries with Home Manager and configure their supported Codex and Hermes integrations.

**Architecture:** Two focused Nix packages install upstream x86_64 Linux release artifacts. A dedicated Home Manager module owns RTK privacy configuration and performs idempotent, native CLI registration after profile links exist, preserving unrelated Codex and Hermes configuration.

**Tech Stack:** Nix, Home Manager activation DAG, systemd user services, Codex CLI, Hermes Agent, Model Context Protocol

## Global Constraints

- Support the repository's configured `x86_64-linux` UOS host.
- Pin RTK `v0.43.0` and fff-mcp `v0.10.1`.
- Install Rust Token Killer from `rtk-ai/rtk`, never the unrelated Rust Type Kit.
- Install the fff MCP server artifact from `dmtrKovalenko/fff`, not its Neovim or C-library artifacts.
- Explicitly disable RTK telemetry.
- Preserve unrelated Codex and Hermes settings and MCP servers.
- Do not expose secrets in commands, logs, generated configuration, or verification output.
- Preserve all unrelated working-tree changes.
- Push only to `origin/uos-home-config`, never `origin/master`.

---

### Task 1: Package RTK and fff-mcp

**Files:**
- Create: `overlays/packages/rtk.nix`
- Create: `overlays/packages/fff-mcp.nix`
- Modify: `overlays/default.nix`

**Interfaces:**
- Consumes: Upstream stable release artifacts for `x86_64-linux`.
- Produces: `pkgs.rtk` with `$out/bin/rtk` and `pkgs.fff-mcp` with `$out/bin/fff-mcp`.

- [ ] **Step 1: Add failing overlay assertions**

Run:

```sh
nix eval --raw .#homeConfigurations.Designers.pkgs.rtk.pname
nix eval --raw .#homeConfigurations.Designers.pkgs.fff-mcp.pname
```

Expected: both evaluations fail because the overlay does not export either package.

- [ ] **Step 2: Create the RTK package**

Create `overlays/packages/rtk.nix`:

```nix
{inputs}:
final: prev: {
  rtk = prev.stdenvNoCC.mkDerivation {
    pname = "rtk";
    version = "0.43.0";

    src = prev.fetchurl {
      url = "https://github.com/rtk-ai/rtk/releases/download/v0.43.0/rtk-x86_64-unknown-linux-musl.tar.gz";
      hash = "sha256-/4oed2ZJbhdSkaha7KHcl8n/bfM+UeWJPR+8eP6ipgk=";
    };

    sourceRoot = ".";

    installPhase = ''
      runHook preInstall
      install -Dm755 rtk "$out/bin/rtk"
      runHook postInstall
    '';

    meta = with prev.lib; {
      description = "Token-optimized proxy for AI coding agent shell commands";
      homepage = "https://github.com/rtk-ai/rtk";
      license = licenses.asl20;
      mainProgram = "rtk";
      platforms = ["x86_64-linux"];
    };
  };
}
```

- [ ] **Step 3: Create the fff-mcp package**

Create `overlays/packages/fff-mcp.nix`:

```nix
{inputs}:
final: prev: {
  fff-mcp = prev.stdenvNoCC.mkDerivation {
    pname = "fff-mcp";
    version = "0.10.1";

    src = prev.fetchurl {
      url = "https://github.com/dmtrKovalenko/fff/releases/download/v0.10.1/fff-mcp-x86_64-unknown-linux-musl";
      hash = "sha256-wXY3wzOvu73qSwPPPhVzJAxBR64SF1bjY6r6PJ0O+1g=";
    };

    dontUnpack = true;

    installPhase = ''
      runHook preInstall
      install -Dm755 "$src" "$out/bin/fff-mcp"
      runHook postInstall
    '';

    meta = with prev.lib; {
      description = "Fast file finder and grep MCP server";
      homepage = "https://github.com/dmtrKovalenko/fff";
      license = licenses.mit;
      mainProgram = "fff-mcp";
      platforms = ["x86_64-linux"];
    };
  };
}
```

- [ ] **Step 4: Export both packages**

Add both imports to `packageOverlays` in `overlays/default.nix`:

```nix
  packageOverlays = [
    (import ./packages/fff-mcp.nix {inherit inputs;})
    (import ./packages/nnn.nix {inherit inputs;})
    (import ./packages/rtk.nix {inherit inputs;})
    (import ./packages/st.nix {inherit inputs;})
  ];
```

- [ ] **Step 5: Format and verify package evaluation**

Run:

```sh
alejandra overlays/default.nix overlays/packages/rtk.nix overlays/packages/fff-mcp.nix
nix eval --raw .#homeConfigurations.Designers.pkgs.rtk.pname
nix eval --raw .#homeConfigurations.Designers.pkgs.fff-mcp.pname
nix build --no-link .#homeConfigurations.Designers.pkgs.rtk
nix build --no-link .#homeConfigurations.Designers.pkgs.fff-mcp
```

Expected: formatting exits zero, evaluations print `rtk` and `fff-mcp`, and both builds succeed.

- [ ] **Step 6: Commit the package layer**

```sh
git add overlays/default.nix overlays/packages/rtk.nix overlays/packages/fff-mcp.nix
git commit -m "Package RTK and fff MCP server"
```

---

### Task 2: Add the Home Manager integration module

**Files:**
- Create: `modules/app/agent-tools/default.nix`
- Modify: `profiles/work/home.nix`

**Interfaces:**
- Consumes: `pkgs.rtk`, `pkgs.fff-mcp`, `~/.nix-profile/bin/codex`, and `~/.nix-profile/bin/hermes`.
- Produces: installed binaries, disabled RTK telemetry, Codex RTK instructions, Hermes RTK plugin, and `fff` MCP registrations in both clients.

- [ ] **Step 1: Add failing module-presence checks**

Run:

```sh
grep -n 'modules/app/agent-tools/default.nix' profiles/work/home.nix
nix eval --json .#homeConfigurations.Designers.config.home.packages |
  grep -E 'rtk|fff-mcp'
```

Expected: the import check and package check fail because the module does not exist or is not imported.

- [ ] **Step 2: Create the integration module**

Create `modules/app/agent-tools/default.nix`:

```nix
{
  config,
  lib,
  pkgs,
  ...
}: let
  homeDir = config.home.homeDirectory;
  profileBin = "${homeDir}/.nix-profile/bin";
  fffBin = "${profileBin}/fff-mcp";
in {
  home.packages = [
    pkgs.fff-mcp
    pkgs.rtk
  ];

  xdg.configFile."rtk/config.toml".text = ''
    [telemetry]
    enabled = false
  '';

  home.activation.configureAgentTools = lib.hm.dag.entryAfter ["linkGeneration"] ''
    export HOME=${lib.escapeShellArg homeDir}
    export RTK_TELEMETRY_DISABLED=1

    rtk_bin=${lib.escapeShellArg "${pkgs.rtk}/bin/rtk"}
    codex_bin=${lib.escapeShellArg "${profileBin}/codex"}
    hermes_bin=${lib.escapeShellArg "${profileBin}/hermes"}
    fff_bin=${lib.escapeShellArg fffBin}

    for executable in "$rtk_bin" "$codex_bin" "$hermes_bin" "$fff_bin"; do
      if [[ ! -x "$executable" ]]; then
        echo "agent-tools activation: required executable is missing: $executable" >&2
        exit 1
      fi
    done

    "$rtk_bin" init -g --codex
    "$rtk_bin" init --agent hermes

    if ! "$codex_bin" mcp get fff 2>/dev/null |
      ${pkgs.gnugrep}/bin/grep -Fq "command: $fff_bin"; then
      "$codex_bin" mcp remove fff >/dev/null 2>&1 || true
      "$codex_bin" mcp add fff -- "$fff_bin"
    fi

    if ! "$hermes_bin" mcp list 2>/dev/null |
      ${pkgs.gnugrep}/bin/grep -Fq "$fff_bin"; then
      "$hermes_bin" mcp remove fff >/dev/null 2>&1 || true
      "$hermes_bin" mcp add fff --command "$fff_bin"
    fi
  '';
}
```

- [ ] **Step 3: Import the module without disturbing existing edits**

Add this line to `baseImports` in `profiles/work/home.nix`:

```nix
    ../../modules/app/agent-tools/default.nix
```

Before editing, inspect the existing diff and preserve every unrelated line:

```sh
git diff -- profiles/work/home.nix
```

- [ ] **Step 4: Format and evaluate the module**

Run:

```sh
alejandra modules/app/agent-tools/default.nix profiles/work/home.nix
nix eval --json .#homeConfigurations.Designers.config.home.packages |
  grep -E 'rtk|fff-mcp'
nix build --no-link .#homeConfigurations.Designers.activationPackage
```

Expected: formatting exits zero, both package names appear, and the activation package builds.

- [ ] **Step 5: Commit only the integration files**

```sh
git add modules/app/agent-tools/default.nix
git add -p profiles/work/home.nix
git diff --cached --check
git commit -m "Integrate RTK and fff with Codex and Hermes"
```

Expected: the staged profile hunk contains only the new module import; unrelated profile edits remain unstaged.

---

### Task 3: Activate and verify both integrations

**Files:**
- Runtime-managed: `~/.config/rtk/config.toml`
- Runtime-mutated by upstream tools: global Codex RTK files, `~/.codex/config.toml`, `~/.hermes/plugins/rtk-rewrite/`, and `~/.hermes/config.yaml`

**Interfaces:**
- Consumes: the built Home Manager activation package.
- Produces: working RTK and fff integrations in Codex and Hermes.

- [ ] **Step 1: Activate with the repository backup policy**

Run:

```sh
env PATH=/nix/var/nix/profiles/default/bin:$HOME/.nix-profile/bin \
  home-manager switch --flake .#Designers -b hm-bak
```

Expected: activation exits zero, including `configureAgentTools`.

- [ ] **Step 2: Verify the RTK binary identity and privacy setting**

Run:

```sh
rtk --version
rtk gain
grep -A1 '^\\[telemetry\\]$' ~/.config/rtk/config.toml
```

Expected: version is `0.43.0`, `rtk gain` displays the Rust Token Killer savings dashboard, and telemetry is `enabled = false`.

- [ ] **Step 3: Verify Codex and Hermes RTK integration artifacts**

Run:

```sh
rtk init --show
test -d ~/.hermes/plugins/rtk-rewrite
grep -n 'rtk-rewrite' ~/.hermes/config.yaml
```

Expected: Codex global integration is reported, the Hermes plugin directory exists, and Hermes enables `rtk-rewrite`.

- [ ] **Step 4: Verify fff-mcp health and registrations**

Run:

```sh
fff-mcp --healthcheck /share/data/sources/home-config
codex mcp get fff
hermes mcp list
hermes mcp test fff
```

Expected: healthcheck succeeds; both clients report `fff` with command `/home/Designers/.nix-profile/bin/fff-mcp`; Hermes discovers the fff search tools.

- [ ] **Step 5: Verify Hermes Gateway remains healthy**

Run:

```sh
systemctl --user restart hermes-gateway.service
sleep 12
systemctl --user is-active hermes-gateway.service
systemctl --user show hermes-gateway.service \
  -p Result -p ExecMainStatus -p NRestarts -p MainPID \
  -p ActiveEnterTimestamp
entered=$(systemctl --user show hermes-gateway.service \
  -p ActiveEnterTimestamp --value)
journalctl --user -u hermes-gateway.service \
  --since "$entered" --no-pager -p err
```

Expected: service is active, `Result=success`, `ExecMainStatus=0`, `NRestarts=0`, and no post-restart error-level log lines are printed.

- [ ] **Step 6: Run repository checks**

Run:

```sh
nix flake check
```

Expected: all configured formatting, Statix, Deadnix, and parse checks pass. Report unrelated `cachix-agent` failures separately if present.

- [ ] **Step 7: Push only the approved branch**

Run:

```sh
git fetch origin uos-home-config
git push origin HEAD:uos-home-config
```

Expected: `origin/uos-home-config` advances to the implementation HEAD. Do not run any push targeting `master`.
