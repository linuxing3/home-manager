let
  username = import ../../nix/username.nix;
  userKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFVyBCKqgnc5Q/4wzaR+eZ7HwLXGNQq6jI4XyKDhTXJT efwmc@nixos";
  generatedUserKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFjKk9OcBNVc24J+zly4Z3IJ2eEZbQVN1LsBBesOE+Xl Designers@Designers-PC";
  ai = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOkEAydXSknuL8JZBeiCjesQy43wlszNVqDHyGDRCDCX linuxing3@ai";
  attrs = {
    publicKeys = [userKey generatedUserKey ai];
    owner = username;
    group = "users";
    mode = "0660";
  };
in {
  "api-keys-new.age" = attrs;
  "cloudflared-office-token.age" = attrs;
}
