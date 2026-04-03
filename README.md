# Home Manager

## Cachix Deploy

This repo exposes a Cachix Deploy spec as `.#deploy`.

The `profiles/work/home.nix` profile enables `services.cachix-agent` and uses the host name from `nix/system-settings.nix` as the agent name.

To activate the deployment:

```bash
export CACHIX_ACTIVATE_TOKEN=ACTIVATE-TOKEN
export CACHIX_AUTH_TOKEN=CACHE-TOKEN

spec=$(nix build .#deploy --print-out-paths)
cachix deploy activate "$spec"
```

If you want to verify the spec without activating it, build it directly:

```bash
nix build .#deploy --no-link
```
