# Network Clients Design

## Goal

Install the Cloudflare Tunnel, Cloudflare WARP, and Tailscale client
packages in the active Home Manager work profile.

## Design

Add a `networkPackages` binding to `profiles/work/home.nix` containing
`cloudflared`, `cloudflare-warp`, and `tailscale`, then append that binding
to `home.packages`.

This keeps network clients separate from the existing file manager,
terminal, editor, collaboration, and workflow package groups.

## Scope

The change installs client binaries only. It does not enable or configure
the Cloudflare WARP or Tailscale system daemons because those require
system-level service management outside this Home Manager profile.

## Validation

Format the edited Nix file and build the active
`homeConfigurations."Designers".activationPackage` output without changing
the lock file. Confirm that the resulting Home Manager package set contains
all three packages.
