---
name: browser-api-auth-workflow
description: Repeatable OMP/Herdr workflow for browser-assisted API setup, local callback completion, non-public verification, safe handoff, and workspace cleanup.
---

# Browser API Auth Workflow

Use this skill when an API setup requires both interactive browser work and local
automation. Typical examples are creator/publishing integrations for YouTube,
Instagram, TikTok, Pinterest, and similar services.

## Workflow

1. **Discover existing state**
   - Identify the target account and provider.
   - Reuse the existing integration scaffold, setup notes, callback helper, verifier,
     and publish helper.
   - Continue from the first incomplete step instead of creating duplicate apps or
     parallel scaffolds.

2. **Prepare the local side**
   - Start the local callback listener when the provider requires one.
   - Confirm the exact redirect URI before changing the provider console.
   - Prepare the local account configuration destination and keep it outside tracked
     source when practical.

3. **Use the existing desktop browser session**
   - Prefer the browser profile the user is already using.
   - Open or create the provider application under the intended account.
   - Enable only the required product/API and permissions.
   - Register the redirect URI expected by the local callback.
   - Confirm any required account linking or professional/business mode.

4. **Respect the human-auth boundary**
   - If the provider presents passkey, 2FA, CAPTCHA, identity review, legal
     acceptance, or account recovery, stop and let the user act.
   - Report the page and required action, then resume from the resulting state.

5. **Complete locally**
   - Return to the existing helper scripts after browser consent.
   - Persist the resulting local account configuration using the project's existing
     conventions and restrictive permissions.
   - Do not print sensitive values into chat, handoff text, or committed files.

6. **Run a non-public smoke check**
   - Verify account identity, API reachability, and required capability.
   - Prefer a verifier that reads account metadata only.
   - Do not publish, upload, or create a public item unless the user explicitly asks
     for that action.

7. **Handoff**
   - Record provider, local account key, non-sensitive provider identity, smoke
     result, blocker if any, and one concrete next action.
   - When another local agent owns the wider workflow, send the same compact handoff.

8. **Workspace hygiene**
   - Keep reusable source, automation loops, runtime data, and backups in separate
     functional directories.
   - Follow an existing numbered-prefix convention when the destination tree uses it.
   - Put browser/config backups in a dedicated backups subtree.
   - After moves, verify the destination exists and the source was removed.

## Failure handling

Classify the failure before changing anything:

- provider-console configuration,
- wrong browser identity,
- redirect mismatch,
- missing permission,
- local callback,
- local account write,
- smoke verification.

Repair only the failing layer and rerun the smallest relevant check. Do not recreate
provider applications or local scaffolds simply because a later step failed.

## Completion criteria

The task is complete when:

- the intended provider/account is configured;
- the local account configuration exists with safe permissions;
- the non-public smoke check succeeds;
- no public action occurred without explicit authorization;
- the handoff contains enough non-sensitive state for the next session;
- generated backups or workspace artifacts are in their functional location.
