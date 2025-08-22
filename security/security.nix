{ inputs, ...}:
{
  imports = [
    inputs.agenix.homeManagerModules.default
  ];
  # age.secretsDir = "/etc/agenix";
  age.secrets = let
    secrets = import ./secrets.nix;
  in
    builtins.mapAttrs (name: attrs: {
      file = ./secrets/${name};
      mode = "0600";
    }) secrets;
}
