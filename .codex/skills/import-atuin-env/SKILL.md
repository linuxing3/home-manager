---
name: import-atuin-env
description: Safely batch-import dotenv-style environment variables into Atuin Dotfiles. Use when users ask to import, migrate, or refresh an env file (especially ~/Downloads/sources/env) with Atuin, while protecting secret values and avoiding accidental sync.
---

# Import environment variables into Atuin

Run `scripts/import-atuin-env [path]` as the user who owns the Atuin store. The default path is `~/Downloads/sources/env`.

The script prevalidates the entire file before changing Atuin, splits only on the first `=`, accepts optional `export`, strips one matching outer quote pair, overwrites existing names, skips empty assignments, and verifies the store with output suppressed. It never sources or evaluates the file and never prints values.

The import is local only. Run `scripts/import-atuin-env path --sync` only when the user explicitly requests uploading variables through Atuin sync. If Atuin’s database is not writable in the execution sandbox, request approval and rerun; do not write a shell rc file instead.

To migrate secrets out of Atuin, create a reviewed names-only file and run `scripts/remove-reviewed-secrets names-file` as a dry run. Run it with `--apply` only after confirming the reviewed names; then re-import only the approved non-secret source values.

Report only counts and errors. Do not expose variable names or values in logs.

## Automation access

Use the managed `agent-env` command for approved automation tools:

```sh
agent-env -- git command
agent-env -- gh command
agent-env -- curl URL
```

It injects Agenix variables only into the child process. Do not place secret values in agent prompts, command arguments, shell startup files, logs, or temporary files. `agenix-env -- command` remains the lower-level explicit interface for commands that have been separately authorized.
