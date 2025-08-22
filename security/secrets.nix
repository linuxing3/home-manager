let
  efwmc = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFVyBCKqgnc5Q/4wzaR+eZ7HwLXGNQq6jI4XyKDhTXJT efwmc@nixos";  ai = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOkEAydXSknuL8JZBeiCjesQy43wlszNVqDHyGDRCDCX linuxing3@ai";
  attrs = {
    publicKeys = [efwmc ai]; 
    owner = "efwmc";
    group = "users";
    mode = "0660";
  };
in {
  "api-keys.age" =  attrs;
  "mail-qq-pass.age" = attrs;
  "mail-mfa-pass.age" = attrs;
}
