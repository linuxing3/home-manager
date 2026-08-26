# Deepin vendor kernel for Phytium D2000 + Glenfly Arise on NixOS.
#
# Prefer linux-6.6.y over EOL/UOS-K5.10-LTS: both ship snd-hda-phytium
# (ft-hda / ALC897) and in-tree DRM_ARISE; 6.6 is far closer to NixOS
# userspace (systemd, udev, btrfs swapfiles) than UOS 4.19 or Deepin 5.10.
#
# Mainline nixpkgs kernels have neither driver. Stock NixOS 6.18 on this
# box is modesetting + HDMI HDA only — no analog ft-hda, no Glenfly DRM.
#
# Usage (from flake/nixos.nix phytium-kernel module):
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
  #
  # Deepin also pulls CIX Sky1 / ArmChina NPU / staging Phytium NPU. Those
  # trees are broken out-of-tree (missing armchina_aipu.h include path) and
  # irrelevant on D2000+Arise — strip them after olddefconfig so they cannot
  # reappear via `default y/m`.
  # Disables may no-op if a symbol is already unreachable; never abort the pass.
  applyConfigTweaks = ''
    cfg() { ./scripts/config "$@" || true; }
    cfg --module DRM_ARISE
    cfg --module SND_HDA_PHYTIUM
    cfg --enable ARCH_PHYTIUM
    cfg --set-str LOCALVERSION ""
    cfg --disable LOCALVERSION_AUTO
    cfg --disable WERROR
    # Shrink build + avoid interactive DEBUG_INFO_BTF prompt during IFD.
    # Vendor defconfig picks DWARF5; flip the DEBUG_INFO choice to NONE.
    cfg --disable DEBUG_INFO_DWARF_TOOLCHAIN_DEFAULT
    cfg --disable DEBUG_INFO_DWARF4
    cfg --disable DEBUG_INFO_DWARF5
    cfg --enable DEBUG_INFO_NONE
    cfg --disable DEBUG_INFO_BTF
    cfg --disable DEBUG_INFO_BTF_MODULES
    # Broken / unused vendor SoC bits (CIX Sky1, ArmChina Zhouyi, staging NPU).
    cfg --disable SOC_CIX
    cfg --disable CIX_SOC_ACPI
    cfg --disable CIX_SKY1_SOCINFO
    cfg --disable ARMCHINA_NPU
    cfg --disable ARMCHINA_NPU_ARCH_V1
    cfg --disable ARMCHINA_NPU_ARCH_V2
    cfg --disable ARMCHINA_NPU_ARCH_V3
    cfg --disable ARMCHINA_NPU_ARCH_V3_1
    cfg --disable ARMCHINA_NPU_SOC_DEFAULT
    cfg --disable ARMCHINA_NPU_SOC_R329
    cfg --disable ARMCHINA_NPU_SOC_SKY1
    cfg --disable SKY1
    cfg --disable MALI_MIDGARD
    cfg --disable MALI_BASE_MODULES
    cfg --disable PHYTIUM_NPU
    cfg --disable PHYTIUM_NPU_PCI
    cfg --disable STAGING
  '';

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

      # First pass: force wanted options, drop broken vendor trees.
      ${applyConfigTweaks}
      make olddefconfig

      # Second pass: olddefconfig re-defaults some symbols (STAGING,
      # ARMCHINA_NPU_ARCH_V3=y, PHYTIUM_NPU=m). Re-assert and resolve again.
      ${applyConfigTweaks}
      make olddefconfig

      # Fail the config derivation if critical bits drifted.
      fail=0
      want() { grep -qxF "$1" .config || { echo "missing $1"; fail=1; }; }
      hate() { grep -qxF "$1" .config && { echo "unwanted $1 still set"; fail=1; } || true; }
      want 'CONFIG_DRM_ARISE=m'
      want 'CONFIG_SND_HDA_PHYTIUM=m'
      want 'CONFIG_ARCH_PHYTIUM=y'
      hate 'CONFIG_SOC_CIX=y'
      hate 'CONFIG_CIX_SOC_ACPI=y'
      hate 'CONFIG_ARMCHINA_NPU=y'
      hate 'CONFIG_ARMCHINA_NPU=m'
      hate 'CONFIG_ARMCHINA_NPU_ARCH_V3=y'
      hate 'CONFIG_PHYTIUM_NPU=y'
      hate 'CONFIG_PHYTIUM_NPU=m'
      hate 'CONFIG_STAGING=y'
      hate 'CONFIG_DEBUG_INFO_BTF=y'
      if [ "$fail" -ne 0 ]; then
        echo '--- offending config lines ---'
        grep -E 'CONFIG_(DRM_ARISE|SND_HDA_PHYTIUM|ARCH_PHYTIUM|SOC_CIX|CIX_|ARMCHINA|PHYTIUM_NPU|STAGING|DEBUG_INFO)=' .config || true
        exit 1
      fi
    '';
    installPhase = ''
      cp .config "$out"
      grep -E 'CONFIG_(DRM_ARISE|SND_HDA_PHYTIUM|ARCH_PHYTIUM|LOCALVERSION|WERROR|ARMCHINA_NPU|CIX_SOC_ACPI|SOC_CIX|PHYTIUM_NPU|STAGING|DEBUG_INFO)=' "$out" || true
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
