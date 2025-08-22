{ userSettings, ...}:
{
  age.secrets = let
    secrets = import ./secrets.nix;
  in
    builtins.mapAttrs (name: attrs: {
      file = ./secrets/${name};
      owner = attrs.owner or userSettings.username;
      group = attrs.group or userSettings.username;
      mode = attrs.mode or "0500";
    }) secrets;
  
}
