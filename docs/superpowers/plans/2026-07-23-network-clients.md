# Network Clients Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Install the Cloudflare Tunnel, Cloudflare WARP, and Tailscale client packages in the active Home Manager work profile.

**Architecture:** Keep the three clients in a dedicated `networkPackages` binding in the existing work profile. Append that binding to `home.packages`; do not add or enable system services.

**Tech Stack:** Nix, Home Manager, nixpkgs

## Global Constraints

- Install `cloudflared`, `cloudflare-warp`, and `tailscale`.
- Install client binaries only.
- Do not enable or configure Cloudflare WARP or Tailscale system daemons.
- Do not update `flake.lock`.

---

### Task 1: Add Network Client Packages

**Files:**
- Modify: `profiles/work/home.nix`

**Interfaces:**
- Consumes: The existing `pkgs` Home Manager module argument and `home.packages` package-list composition.
- Produces: A `networkPackages` list included in the active profile's `home.packages`.

- [ ] **Step 1: Verify the packages are not already declared**

Run:

```bash
grep -n -E 'cloudflared|cloudflare-warp|tailscale' profiles/work/home.nix
```

Expected: exit status 1 with no output.

- [ ] **Step 2: Add the network package group**

Add this binding after `workflowPackages`:

```nix
  networkPackages = with pkgs; [
    cloudflared
    cloudflare-warp
    tailscale
  ];
```

Append it to the package composition:

```nix
  home.packages =
    fileManagerPackages
    ++ terminalPackages
    ++ editorPackages
    ++ collaborationPackages
    ++ workflowPackages
    ++ networkPackages;
```

- [ ] **Step 3: Format the changed Nix file**

Run:

```bash
alejandra profiles/work/home.nix
```

Expected: exit status 0.

- [ ] **Step 4: Confirm all package declarations are present**

Run:

```bash
grep -n -E 'cloudflared|cloudflare-warp|tailscale|networkPackages' profiles/work/home.nix
```

Expected: one declaration for each package, one `networkPackages` binding, and one inclusion in `home.packages`.

- [ ] **Step 5: Build the active Home Manager configuration**

Run:

```bash
nix build '.#homeConfigurations."Designers".activationPackage' --no-link --no-update-lock-file
```

Expected: exit status 0 without modifying `flake.lock`.

- [ ] **Step 6: Commit the focused change when Git is available**

```bash
git add profiles/work/home.nix docs/superpowers/specs/2026-07-23-network-clients-design.md docs/superpowers/plans/2026-07-23-network-clients.md
git commit -m "Add network client packages"
```

Expected: one commit containing only the profile change and its design/plan documentation.
