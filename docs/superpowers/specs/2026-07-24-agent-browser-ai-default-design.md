# Agent Browser AI Default Design

## Goal

Make the Nix-installed `agent-browser` the preferred headless browser for AI
agents and repository automation without changing the graphical browser used by
desktop applications or OAuth login flows.

## Configuration

- Keep `BROWSER = userSettings.browser` unchanged so desktop URL handling
  continues to use `chromium-browser`.
- Add Home Manager session variables that advertise the Nix-resolved
  `agent-browser` executable for AI automation.
- Keep `agent-browser` headless by default and retain the package's existing
  engine configuration.
- Add a concise section to the repository `AGENTS.md` directing AI agents to use
  `agent-browser` for browser automation and to load its bundled core skill
  before complex interactions.

The environment variables provide a durable machine-readable preference.
`AGENTS.md` provides an explicit fallback for agents that do not recognize a
shared browser-selection variable.

## Boundaries

- Do not change XDG MIME associations, `xdg-open`, or the desktop default
  browser.
- Do not replace the general-purpose `BROWSER` variable.
- Do not install another browser or add a new dependency.
- Do not change the existing `agent-browser` package implementation.

## Verification

1. Format the changed Nix file with Alejandra.
2. Build `.#homeConfigurations.Designers.activationPackage`.
3. Activate the Home Manager profile with the existing backup policy.
4. Verify that the AI-browser variables resolve to the Nix-installed
   `agent-browser`.
5. Run a live headless `agent-browser read` smoke test.
6. Confirm `BROWSER` still resolves to `chromium-browser`.
