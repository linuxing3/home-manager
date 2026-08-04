# Agent Browser AI Default Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the Nix-installed `agent-browser` the explicit headless browser for AI agents while preserving Chromium for desktop and OAuth use.

**Architecture:** Home Manager exports agent-specific browser variables using the exact Nix store executable. Repository guidance tells agents that do not recognize those variables to invoke the same CLI directly. The general `BROWSER` variable and desktop MIME associations remain unchanged.

**Tech Stack:** Nix, Home Manager, `agent-browser`, Markdown

## Global Constraints

- Keep `BROWSER = userSettings.browser` unchanged.
- Do not change XDG MIME associations or `xdg-open`.
- Do not install another browser or add a dependency.
- Do not modify the existing `agent-browser` package implementation.
- Preserve unrelated worktree changes.

---

### Task 1: Configure and verify the AI browser default

**Files:**
- Modify: `profiles/work/home.nix:89-94`
- Modify: `AGENTS.md:35-37`

**Interfaces:**
- Consumes: `pkgs.agent-browser`, `lib.getExe`, and the existing Home Manager session-variable configuration.
- Produces: `AI_BROWSER` and `AGENT_BROWSER` as absolute paths to the Nix `agent-browser` executable, plus repository instructions for AI agents.

- [ ] **Step 1: Run pre-change assertions**

Run:

```bash
grep -q 'AI_BROWSER = lib.getExe pkgs.agent-browser;' profiles/work/home.nix
grep -q 'AGENT_BROWSER = lib.getExe pkgs.agent-browser;' profiles/work/home.nix
grep -q '^## AI Browser Automation' AGENTS.md
```

Expected: each assertion fails because the configuration and guidance do not yet exist.

- [ ] **Step 2: Add the Home Manager session variables**

Add these entries to `home.sessionVariables` immediately before the existing `BROWSER` entry:

```nix
AI_BROWSER = lib.getExe pkgs.agent-browser;
AGENT_BROWSER = lib.getExe pkgs.agent-browser;
BROWSER = userSettings.browser;
```

This retains the graphical browser and anchors AI automation to a Nix store executable.

- [ ] **Step 3: Add repository agent guidance**

Append this section to `AGENTS.md`:

```markdown
## AI Browser Automation

Use the Nix-installed `agent-browser` for headless browser automation. Read its
version-matched core guidance with `agent-browser skills get core --full` before
complex interactions. Keep graphical links and OAuth flows on the configured
desktop `BROWSER`; do not replace desktop MIME associations with
`agent-browser`.
```

- [ ] **Step 4: Run static assertions and formatting**

Run:

```bash
grep -q 'AI_BROWSER = lib.getExe pkgs.agent-browser;' profiles/work/home.nix
grep -q 'AGENT_BROWSER = lib.getExe pkgs.agent-browser;' profiles/work/home.nix
grep -q '^## AI Browser Automation' AGENTS.md
alejandra profiles/work/home.nix
git diff --check -- profiles/work/home.nix AGENTS.md
```

Expected: all commands exit successfully with no formatting or whitespace errors.

- [ ] **Step 5: Build and activate the profile**

Run:

```bash
nix build .#homeConfigurations.Designers.activationPackage --no-link
env PATH=/nix/var/nix/profiles/default/bin:$HOME/.nix-profile/bin \
  home-manager switch --flake .#Designers -b hm-bak
```

Expected: the focused activation-package build succeeds and Home Manager activates. Report the existing unrelated `cachix-agent.service` failure separately if it recurs.

- [ ] **Step 6: Verify the activated environment and live browser behavior**

Run:

```bash
bash -lc '
  test "$BROWSER" = "chromium-browser"
  test "$AI_BROWSER" = "$AGENT_BROWSER"
  test -x "$AI_BROWSER"
  "$AI_BROWSER" --version
  "$AI_BROWSER" read https://example.com
'
```

Expected: `BROWSER` remains `chromium-browser`; both AI variables point to one executable Nix store path; `agent-browser` reports its version; the headless read returns the Example Domain page.

- [ ] **Step 7: Commit the focused implementation**

Run:

```bash
git add profiles/work/home.nix AGENTS.md
git commit -m "Configure agent browser for AI automation"
```

Expected: one commit containing only the two implementation files. Existing unrelated worktree changes remain uncommitted.
