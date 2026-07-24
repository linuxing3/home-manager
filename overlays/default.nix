{inputs}: final: prev: let
  packageOverlays = [
    (import ./packages/fff-mcp.nix {inherit inputs;})
    (import ./packages/nnn.nix {inherit inputs;})
    (import ./packages/rtk.nix {inherit inputs;})
    (import ./packages/st.nix {inherit inputs;})
  ];
in
  builtins.foldl' (acc: overlayFn: acc // (overlayFn final prev)) {} packageOverlays
