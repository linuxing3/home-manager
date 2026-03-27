entries:
let
  names = builtins.attrNames entries;
  isContainerModule =
    name:
    entries.${name} == "regular"
    && builtins.match ".*\\.nix" name != null;
in
builtins.sort builtins.lessThan (
  map (name: builtins.replaceStrings [ ".nix" ] [ "" ] name) (builtins.filter isContainerModule names)
)
