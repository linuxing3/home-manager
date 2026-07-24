# Hermes Gateway Agenix Environment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Run the Hermes Gateway user service through `agenix-env` while keeping secret values confined to the child process.

**Architecture:** Override the generated Hermes systemd user unit with its existing drop-in. Use stable Home Manager profile paths for both wrappers, then verify the effective unit, Agenix materialization, service health, and new logs.

**Tech Stack:** systemd user services, Agenix, Home Manager, Hermes Agent

## Global Constraints

- Never display or log plaintext secret values.
- Do not modify `~/.hermes/.env`.
- Use `/home/Designers/.nix-profile/bin` paths so profile upgrades select the active wrappers.
- Keep the existing service restart policy.

---

### Task 1: Wrap Hermes Gateway with Agenix

**Files:**
- Modify: `/home/Designers/.config/systemd/user/hermes-gateway.service.d/nix-wrapper.conf`

**Interfaces:**
- Consumes: `/home/Designers/.nix-profile/bin/agenix-env`, `/home/Designers/.nix-profile/bin/hermes`, and the materialized Agenix environment used by `agenix-env`.
- Produces: An effective `ExecStart` that injects Agenix variables only into the Hermes Gateway child process.

- [ ] **Step 1: Verify the current unit does not yet use `agenix-env`**

Run:

```sh
systemctl --user show hermes-gateway.service -p ExecStart
```

Expected: output contains `/home/Designers/.nix-profile/bin/hermes gateway run` and does not contain `/home/Designers/.nix-profile/bin/agenix-env`.

- [ ] **Step 2: Verify Agenix prerequisites without printing secret contents**

Run:

```sh
systemctl --user show agenix.service \
  -p Type -p Result -p ExecMainStatus
stat -Lc '%a %U:%G %n' "$XDG_RUNTIME_DIR/agenix/api-keys-new.age"
test -x /home/Designers/.nix-profile/bin/agenix-env
test -x /home/Designers/.nix-profile/bin/hermes
/home/Designers/.nix-profile/bin/agenix-env -- /usr/bin/true
```

Expected: `agenix.service` is `Type=oneshot` with `Result=success` and
`ExecMainStatus=0`; the materialized file is owned by `Designers` with mode
`600`; both executable checks and the non-outputting wrapper smoke test exit
zero.

- [ ] **Step 3: Update the drop-in**

Set the complete file to:

```ini
[Service]
ExecStart=
ExecStart=/home/Designers/.nix-profile/bin/agenix-env -- /home/Designers/.nix-profile/bin/hermes gateway run
ExecStopPost=
```

- [ ] **Step 4: Reload and restart the service**

Run:

```sh
systemctl --user daemon-reload
systemctl --user restart hermes-gateway.service
```

Expected: both commands exit zero.

- [ ] **Step 5: Verify the effective command and runtime health**

Run:

```sh
sleep 12
systemctl --user is-enabled hermes-gateway.service
systemctl --user is-active hermes-gateway.service
systemctl --user show hermes-gateway.service \
  -p ExecStart -p ActiveState -p SubState -p Result \
  -p ExecMainStatus -p NRestarts -p MainPID
/home/Designers/.nix-profile/bin/hermes gateway status
```

Expected: the service is `enabled`, `active`, and `running`; `ExecStart` begins with `agenix-env`; `Result=success`, `ExecMainStatus=0`, and `NRestarts=0`; Hermes reports that the user gateway service is running.

- [ ] **Step 6: Check only post-restart warnings and errors**

Run:

```sh
journalctl --user -u hermes-gateway.service \
  --since "$(systemctl --user show hermes-gateway.service \
    -p ActiveEnterTimestamp --value)" \
  --no-pager -p warning
```

Expected: no Agenix, decryption, missing-file, Python import, or startup errors. Platform connectivity or access-control warnings may remain and must be reported separately.
