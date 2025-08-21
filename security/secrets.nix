let
efwmc = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFVyBCKqgnc5Q/4wzaR+eZ7HwLXGNQq6jI4XyKDhTXJT efwmc@nixos";
ai = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOkEAydXSknuL8JZBeiCjesQy43wlszNVqDHyGDRCDCX linuxing3@ai";
in {
  "api-keys.age".publicKeys = [efwmc ai]; 
  "mail-qq-pass.age".publicKeys = [efwmc ai]; 
  "mail-mfa-pass.age".publicKeys = [efwmc ai]; 
}
