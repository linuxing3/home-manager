# Deepin vendor kernel for Phytium D2000 + Glenfly Arise on NixOS.
#
# Prefer linux-6.6.y over EOL/UOS-K5.10-LTS: both ship snd-hda-phytium
# (ft-hda / ALC897) and in-tree DRM_ARISE; 6.6 is far closer to NixOS
# userspace (systemd, udev, btrfs swapfiles) than UOS 4.19 or Deepin 5.10.
#
# Mainline nixpkgs kernels have neither driver. Stock NixOS 6.18 on this
# box is modesetting + HDMI HDA only — no analog ft-hda, no Glenfly DRM.
#
# Usage (from disko/flake.nix):
#   boot.kernelPackages = import ./kernel-phytium.nix {
#     inherit pkgs lib;
#     src = deepin-kernel;
#   };
{
  lib,
  pkgs,
  src,
  # Bump when the deepin tip advances past Makefile VERSION.PATCHLEVEL.SUBLEVEL.
  # deepin-community/kernel linux-6.6.y tip (Makefile SUBLEVEL).
  # Vendor defconfig sets LOCALVERSION=-arm64-desktop-hwe; we clear it below
  # so modDirVersion stays the plain upstream triple.
  version ? "6.6.152",
  modDirVersion ? version,
}: let
  # Vendor arm64 desktop defconfig already enables SND_HDA_PHYTIUM=m and
  # ARCH_PHYTIUM. DRM_ARISE defaults to m in Kconfig but is absent from
  # the defconfig file, so force it before olddefconfig.
  configfile = pkgs.stdenvNoCC.mkDerivation {
    name = "deepin-phytium-${version}.config";
    inherit src;
    nativeBuildInputs = with pkgs.buildPackages; [
      stdenv.cc
      bison
      flex
      bc
      openssl
      perl
      elfutils
      python3
    ];
    dontConfigure = true;
    postPatch = ''
      patchShebangs scripts/config
    '';
    buildPhase = ''
      set -eu
      export ARCH=${pkgs.stdenv.hostPlatform.linuxArch}
      make deepin_arm64_desktop_defconfig
      if ./scripts/config --module DRM_ARISE \
           && ./scripts/config --module SND_HDA_PHYTIUM \
           && ./scripts/config --enable ARCH_PHYTIUM \
           && ./scripts/config --set-str LOCALVERSION "" \
           && ./scripts/config --disable LOCALVERSION_AUTO \
           && ./scripts/config --disable WERROR \
           && ./scripts/config --disable ARMCHINA_NPU \
           && ./scripts/config --disable CIX_SOC_ACPI \
           && ./scripts/config --disable SOC_CIX \
           && ./scripts/config --disable PHYTIUM_NPU \
           && ./scripts/config --disable PHYTIUM_NPU_PCI \
           && ./scripts/config --disable STAGING; then
        :
      else
        printf '%s\n' \
          'CONFIG_DRM_ARISE=m' \
          'CONFIG_SND_HDA_PHYTIUM=m' \
          'CONFIG_ARCH_PHYTIUM=y' \
          'CONFIG_LOCALVERSION=""' \
          '# CONFIG_LOCALVERSION_AUTO is not set' \
          '# CONFIG_WERROR is not set' \
          '# CONFIG_ARMCHINA_NPU is not set' \
          '# CONFIG_CIX_SOC_ACPI is not set' \
          '# CONFIG_SOC_CIX is not set' \
          '# CONFIG_PHYTIUM_NPU is not set' \
          '# CONFIG_PHYTIUM_NPU_PCI is not set' \
          '# CONFIG_STAGING is not set' >> .config
      fi
      make olddefconfig
    '';
    installPhase = ''
      cp .config "$out"
      grep -E 'CONFIG_(DRM_ARISE|SND_HDA_PHYTIUM|ARCH_PHYTIUM|LOCALVERSION|WERROR|ARMCHINA_NPU|CIX_SOC_ACPI|SOC_CIX|PHYTIUM_NPU|STAGING)=' "$out" || true
    '';
  };

  kernel = pkgs.linuxKernel.manualConfig {
    inherit (pkgs) lib stdenv;
    inherit src version modDirVersion configfile;
    allowImportFromDerivation = true;
    extraMeta = {
      branch = "6.6";
      description = "Deepin linux-6.6.y with Phytium HDA + Glenfly Arise";
      hydraPlatforms = [];
    };
  };
in
  pkgs.linuxPackagesFor kernel
