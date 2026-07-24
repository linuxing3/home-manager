# RTK Integration for Codex and Hermes

## Goal

Install Rust Token Killer (`rtk-ai/rtk`) through Home Manager and configure
its supported Codex and Hermes integrations without enabling telemetry or
using an imperative binary installer.

## Package Management

Add a focused `rtk` package override under `overlays/packages/`. Pin the
latest stable upstream release, source hash, and Cargo dependency hash.
Export it from the existing project overlay and install it in the active
`work` profile.

The packaged command must be the Rust Token Killer from `rtk-ai/rtk`, not the
unrelated Rust Type Kit package. Validate this with both `rtk --version` and
`rtk gain`.

## Agent Integrations

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

## Privacy and Failure Behavior

Manage `~/.config/rtk/config.toml` through Home Manager with telemetry
explicitly disabled. Preserve RTK's graceful degradation: if rewriting fails,
the original command must remain usable.

Do not route the Hermes Gateway itself through RTK. RTK only rewrites terminal
commands issued by the Hermes agent plugin.

## Verification

1. Format and evaluate the affected Nix files.
2. Build the Home Manager activation package without activating it.
3. Activate with the existing backup policy.
4. Verify `rtk --version`, `rtk gain`, and the Codex integration status.
5. Verify the Hermes plugin files and `plugins.enabled` entry.
6. Restart `hermes-gateway.service`; require `active`, `Result=success`,
   `ExecMainStatus=0`, no restart loop, and no new error-level logs.
7. Run a harmless rewrite check for each integration without exposing
   secrets.

## Delivery

Commit only RTK-related files. Preserve existing unrelated working-tree
changes. Push the completed commits to `origin/uos-home-config`; never push
them to `origin/master`.
