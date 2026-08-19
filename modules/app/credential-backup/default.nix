{pkgs, ...}: let
  credentialVault = pkgs.writeShellApplication {
    name = "credential-vault";
    runtimeInputs = [
      pkgs.bitwarden-cli
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
  credentialUsbRecovery = pkgs.writeShellApplication {
    name = "credential-usb-recovery";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.findutils
      pkgs.gawk
      pkgs.gnused
      credentialVault
    ];
    text = builtins.readFile ./credential-usb-recovery.sh;
  };
in {
  home.packages = [
    credentialVault
    credentialUsbRecovery
  ];
}
