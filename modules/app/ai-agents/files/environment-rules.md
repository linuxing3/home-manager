# Global User Instructions

- When a command needs protected environment variables or credentials, run it through `agenix-env -- <command>`.
- This is an `aarch64-linux` NixOS environment. The Home Manager/NixOS configuration source is `/home/Designers/home-config`.
- For changes to that configuration: run `nix flake check` and build the affected output before activation. Use Home Manager rather than `nix profile add` for Pi, Codex, Cursor Agent, Herdr, Collie, and Orca. Do not switch the `sda-phytium` NixOS host while booted from NVMe.
- For headless browser automation, use the Nix-installed `agent-browser` and read `agent-browser skills get core --full` before complex interactions. Keep graphical links and OAuth flows in the configured desktop browser; do not change desktop MIME associations.
- Keep secrets encrypted with Agenix; never put plaintext secrets in configuration or repositories.
