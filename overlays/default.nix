{inputs}: final: prev: let
  packageOverlays = [
    (import ./packages/agent-browser.nix)
    (import ./packages/cliamp.nix)
    (import ./packages/collie.nix)
    (import ./packages/herdr.nix)
    (import ./packages/cli-proxy-api.nix)
    (import ./packages/lightpanda.nix)
    (import ./packages/muse-cli.nix)
    (import ./packages/dsh.nix)
    (import ./packages/fff-mcp.nix {inherit inputs;})
    (import ./packages/nnn.nix {inherit inputs;})
    (import ./packages/omp.nix)
    (import ./packages/pi.nix)
    (import ./packages/pi-switch.nix {inherit inputs;})
    (import ./packages/rtk.nix {inherit inputs;})
    (import ./packages/secretspec.nix {inherit inputs;})
    (import ./packages/st.nix {inherit inputs;})
    (import ./packages/ttfx.nix)
    (import ./packages/omawrite.nix)
    (import ./packages/omacalc.nix)
    (import ./packages/omacut.nix)
    (import ./packages/aether.nix)
    (import ./packages/dwm.nix)
    (import ./packages/webcodex.nix)
  ];
in
  builtins.foldl' (acc: overlayFn: acc // (overlayFn final prev)) {} packageOverlays
