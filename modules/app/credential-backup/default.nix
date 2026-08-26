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
      pkgs.udisks2
      pkgs.util-linux
      credentialVault
    ];
    text = builtins.readFile ./credential-usb-recovery.sh;
  };
  keyvaultTuiUnwrapped = pkgs.buildGoModule {
    pname = "keyvault-tui";
    version = "0.1.0";
    src = ./tui;
    vendorHash = "sha256-i3+SFzqKYjIPJtyXigCYr2QqgdpxFqtCIVsd4VCevJk=";
    ldflags = ["-s" "-w"];
  };
  keyvaultTui = pkgs.symlinkJoin {
    name = "keyvault-tui";
    paths = [keyvaultTuiUnwrapped];
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/keyvault-tui \
        --prefix PATH : ${pkgs.lib.makeBinPath [
        credentialVault
        credentialUsbRecovery
        pkgs.gnupg
        pkgs.coreutils
      ]}
    '';
  };
in {
  home.packages = [
    credentialVault
    credentialUsbRecovery
    keyvaultTui
  ];
}
