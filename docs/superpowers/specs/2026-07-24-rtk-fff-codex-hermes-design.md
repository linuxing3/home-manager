# RTK and fff-mcp Integration for Codex and Hermes

## Goal

Install Rust Token Killer (`rtk-ai/rtk`) through Home Manager and configure
its supported Codex and Hermes integrations. Install the `fff-mcp` server from
`dmtrKovalenko/fff` and register it with both clients. Do not enable telemetry
or use imperative binary installers.

## Package Management

Add focused `rtk` and `fff-mcp` package definitions under
`overlays/packages/`. Pin each latest stable upstream release and all source,
binary, and dependency hashes. Export both packages from the existing project
overlay and install them in the active `work` profile.

The packaged command must be the Rust Token Killer from `rtk-ai/rtk`, not the
unrelated Rust Type Kit package. Validate this with both `rtk --version` and
`rtk gain`.

The packaged `fff-mcp` must be the MCP server artifact from
`dmtrKovalenko/fff`, not the Neovim plugin or C library artifact. Validate it
with `fff-mcp --healthcheck` against this repository.

## RTK Agent Integrations

Use RTK's upstream-supported initializers because their generated formats are
version-coupled to the RTK binary:

```sh
rtk init -g --codex
rtk init --agent hermes
```

Run them from an idempotent Home Manager activation step after files have been
linked. The activation step must:

- resolve the RTK binary from the pinned Nix package;
- run non-interactively;
- leave existing unrelated Codex and Hermes configuration intact;
- fail activation with an actionable message if either initializer fails;
- never place secrets in arguments, output, or generated files.

Codex receives RTK's global instruction integration. Hermes receives the
upstream Python rewrite plugin under `~/.hermes/plugins/rtk-rewrite/` and the
corresponding `plugins.enabled` entry in its configuration.

## fff-mcp Agent Integrations

Register the same Home Manager-managed `fff-mcp` executable as a stdio MCP
server named `fff` in both clients.

Use the clients' supported configuration commands from an idempotent Home
Manager activation step:

```sh
codex mcp add fff -- /home/Designers/.nix-profile/bin/fff-mcp
hermes mcp add fff \
  --command /home/Designers/.nix-profile/bin/fff-mcp
```

Before adding, inspect the existing `fff` entry. If it already points to the
managed executable, do nothing. If it points elsewhere, remove and recreate
only the `fff` entry. Preserve every unrelated MCP server and all other Codex
and Hermes configuration.

The activation migrates the current Codex entry away from
`~/.local/bin/fff-mcp`. Hermes stores its entry under
`mcp_servers.fff` in `~/.hermes/config.yaml`.

## Privacy and Failure Behavior

Manage `~/.config/rtk/config.toml` through Home Manager with telemetry
explicitly disabled. Preserve RTK's graceful degradation: if rewriting fails,
the original command must remain usable.

Do not route the Hermes Gateway itself through RTK. RTK only rewrites terminal
commands issued by the Hermes agent plugin.

`fff-mcp` receives repository paths and search expressions over stdio. It
requires no credentials. Do not add environment variables or network
transports to either client entry.

Direct Codex and Hermes MCP operation is in scope. The known elicitation hang
in the separate Claude Code `openai-codex` review plugin is out of scope and
must be reported rather than treated as a direct `fff-mcp` failure.

## Verification

1. Format and evaluate the affected Nix files.
2. Build the Home Manager activation package without activating it.
3. Activate with the existing backup policy.
4. Verify `rtk --version`, `rtk gain`, and the Codex integration status.
5. Verify the Hermes RTK plugin files and `plugins.enabled` entry.
6. Run `fff-mcp --healthcheck` against the repository.
7. Verify Codex and Hermes list `fff` with the managed executable, then probe
   MCP discovery and a harmless repository search in each client.
8. Restart `hermes-gateway.service`; require `active`, `Result=success`,
   `ExecMainStatus=0`, no restart loop, and no new error-level logs.
9. Run a harmless RTK rewrite check for each integration without exposing
   secrets.

## Delivery

Commit only RTK- and `fff-mcp`-related files. Preserve existing unrelated
working-tree changes. Push the completed commits to
`origin/uos-home-config`; never push them to `origin/master`.
