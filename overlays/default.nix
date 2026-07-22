{ inputs }:
final: prev:
let
  packageOverlays = [
    (import ./packages/nnn.nix { inherit inputs; })
    (import ./packages/st.nix { inherit inputs; })
  ];
in
builtins.foldl' (acc: overlayFn: acc // (overlayFn final prev)) { } packageOverlays
