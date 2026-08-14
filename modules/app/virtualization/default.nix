{pkgs, ...}: {
  # User-space clients only. The UOS host remains responsible for the KVM
  # device, libvirt daemon, networking, and group membership.
  home.packages = with pkgs; [
    qemu_kvm
    libvirt
    virt-manager
    virt-viewer
    swtpm
  ];
}
