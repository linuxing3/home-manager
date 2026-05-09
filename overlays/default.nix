{ inputs }:
final: prev:
let
  packageOverlays = [
    (import ./packages/oxwm.nix { inherit inputs; })
    (import ./packages/hermes-agent.nix { inherit inputs; })
    (import ./packages/lancedb-mcp.nix { inherit inputs; })
    (import ./packages/lightpanda.nix { inherit inputs; })
    (import ./packages/agent-browser.nix { inherit inputs; })
    (import ./packages/notebooklm-py.nix { inherit inputs; })
    (import ./packages/notebooklm-client.nix { inherit inputs; })
    (import ./packages/hermes-web-ui.nix { inherit inputs; })
    (import ./packages/nnn.nix { inherit inputs; })
    (import ./packages/st.nix { inherit inputs; })
    (import ./packages/dwm.nix { inherit inputs; })
    (import ./packages/libsForQt5.nix { inherit inputs; })
    (import ./packages/helix-steel-system.nix { inherit inputs; })
    (import ./packages/opencode-desktop.nix { inherit inputs; })
    (import ./packages/mcp-cli.nix { inherit inputs; })
    (import ./packages/openfang.nix { inherit inputs; })
    (import ./packages/open-design.nix { inherit inputs; })
    (import ./packages/tdf.nix { inherit inputs; })
    (import ./packages/jcode.nix { inherit inputs; })
  ];
in
builtins.foldl' (acc: overlayFn: acc // (overlayFn final prev)) { } packageOverlays
