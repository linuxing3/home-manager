# Browser-assisted API workflow

This runbook captures the reusable automation pattern exercised on 2026-09-24 while
running `omp` inside Herdr. It applies to browser-mediated API setup such as
YouTube, Instagram Graph, TikTok Content Posting, Pinterest, and similar services.

The executable checklist is:

`.codex/skills/browser-api-auth-workflow/SKILL.md`

## Core pattern

```text
discover existing scaffold
        |
        v
prepare callback + local account destination
        |
        v
use existing logged-in desktop browser
        |
        v
configure provider app / permissions / redirect
        |
        v
interactive consent
        |
        +---- human verification? ----> user completes it
        |
        v
complete local account setup
        |
        v
non-public smoke check
        |
        +---- failure ----> repair only failing layer
        |
        v
compact handoff
        |
        v
wait for explicit authorization before public action
```

## OMP + Herdr operating convention

OMP is the orchestration shell; Herdr is the pane/session host. Keep work attached to
the existing project or scaffold instead of generating parallel copies.

When the user is already logged into a service in the desktop browser, preserve that
browser state. A fresh isolated profile can lose the account state required to
finish the setup.

## Reuse before rebuild

Before changing a provider console, look for:

- callback helper;
- account-exchange helper;
- smoke verifier;
- publish helper;
- setup README;
- example account configuration;
- existing real account configuration.

Continue from the first incomplete state. Avoid duplicate provider applications,
redirect registrations, or local account files unless there is a concrete reason.

## Verification boundary

Authentication/setup success is not publication authorization.

A smoke check should prove identity and API reachability without creating public
content. Even when a publishing helper is ready, stop before the real post/upload
unless the user explicitly requests it.

## Human-intervention boundary

At passkey, 2FA, CAPTCHA, identity review, account recovery, payment, or legal
acceptance screens:

1. stop automation;
2. identify the current page and required user action;
3. let the user complete it;
4. resume from the resulting browser state.

Do not loop on or work around security challenges.

## Workspace organization

The same session also established a useful organization rule for the studio tree:
separate code and durable automation from runtime data and backups.

Use the destination tree's existing numbered functional prefixes when present.
Backups belong in a dedicated backups subtree and should retain descriptive names.
After a move, verify both the new destination and the absence of the old source.

Browser shortcut/config backups should not be mixed with agent source or automation
loops.

## Minimal handoff record

```text
provider: <name>
account: <local account key>
identity: <non-sensitive provider account/channel id>
display: <username or channel>
smoke: OK | FAILED
next: <one concrete next action>
```

This is enough for a later OMP session or another local agent to continue without
copying session history or sensitive values.

## Related files

- `.codex/skills/browser-api-auth-workflow/SKILL.md`
- `docs/agent-tools.md`
- `docs/ai-agents.md`
