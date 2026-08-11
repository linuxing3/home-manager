{pkgs, ...}: let
  credentialVault = pkgs.writeShellApplication {
    name = "credential-vault";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.findutils
      pkgs.gnugrep
      pkgs.gnutar
      pkgs.jq
      pkgs.rclone
      pkgs.util-linux
    ];
    text = builtins.readFile ./credential-vault.sh;
  };
in {
  home.packages = [credentialVault];
}
