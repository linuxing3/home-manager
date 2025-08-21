let
local = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFVyBCKqgnc5Q/4wzaR+eZ7HwLXGNQq6jI4XyKDhTXJT efwmc@nixos";
in {
  "api-keys.age".publicKeys = [local]; 
}
