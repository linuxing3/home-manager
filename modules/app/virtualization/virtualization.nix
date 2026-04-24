{ config, lib, pkgs, ... }:

let
  cfg = config.my.features.home;
in
{
  options.my.features.home.virtualization = lib.mkEnableOption "Enable virtualization helper module";

  config = lib.mkIf cfg.virtualization {
    # Various packages related to virtualization, compatability and sandboxing
    home.packages = with pkgs; [
      # Virtual Machines and wine
      # podman
      # podman-compose
      # podman-tui
      # podman-desktop
      # podman-bootc

      # docker
      # docker-compose

      # libvirt
      # virt-manager
      # qemu
      # uefi-run
      # lxc
      # swtpm
      # bottles


      # Filesystems
      virtiofsd
      # dosfstools
    ];

  #   home.file.".config/libvirt/qemu.conf".text = ''
  # nvram = ["/run/libvirt/nix-ovmf/OVMF_CODE.fd:/run/libvirt/nix-ovmf/OVMF_VARS.fd"]
  #   '';
  };
}
