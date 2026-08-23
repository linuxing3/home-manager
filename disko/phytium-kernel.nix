# Opt-in NixOS module: Deepin linux-6.6.y with Phytium HDA + Glenfly Arise.
#
# Does not replace the default sda profile (mainline 6.18). Enable via
# nixosConfigurations.sda-phytium or by importing this module yourself.
{
  config,
  lib,
  pkgs,
  deepin-kernel,
  ...
}: let
  phytiumPackages = import ./kernel-phytium.nix {
    inherit lib pkgs;
    src = deepin-kernel;
  };
in {
  boot.kernelPackages = phytiumPackages;

  # Analog ALC897 on PHYT0006:00 is snd-hda-phytium (module name historically
  # ft-hda on UOS 4.19). HDMI stays on snd-hda-intel / codec-hdmi.
  boot.kernelModules = [
    "snd_hda_phytium"
    "snd_hda_intel"
    "snd_hda_codec_hdmi"
    "arise"
  ];

  boot.initrd.availableKernelModules = [
    "arise"
  ];

  # Kernel DRM arise provides KMS; keep X on modesetting until a matching
  # Glenfly userspace DDX/GL stack is packaged for NixOS.
  services.xserver.videoDrivers = lib.mkForce ["modesetting"];

  environment.etc."X11/xorg.conf.d/10-glenfly.conf".text = lib.mkForce ''
    Section "OutputClass"
        Identifier "glenfly-arise"
        MatchDriver "arise"
        Driver "modesetting"
    EndSection

    Section "Device"
        Identifier "Glenfly Arise1020"
        Driver "modesetting"
        BusID "PCI:1:0:0"
        Option "AccelMethod" "glamor"
        Option "PageFlip" "on"
        Option "SWcursor" "off"
    EndSection
  '';

  # Same WirePlumber shape as hardware-host.nix. snd-hda-phytium may expose
  # phytiumhda instead of fthda; PHYT0006 platform match still applies.
  services.pipewire.wireplumber.extraConfig."51-fthda-analog" = lib.mkForce {
    "monitor.alsa.rules" = [
      {
        matches = [
          {"device.name" = "~alsa_card.platform-PHYT0006.*";}
        ];
        actions.update-props = {
          "device.profile" = "output:stereo-fallback";
          "device.description" = "Phytium ft-hda analog";
        };
      }
      {
        matches = [
          {"device.name" = "~alsa_card.pci-0000_01_00.1";}
        ];
        actions.update-props = {
          "device.profile" = "off";
          "device.description" = "Glenfly HDMI audio";
        };
      }
    ];
  };

  warnings = [
    ''
      phytium-kernel: building Deepin linux-6.6.y from source (large, slow,
      first-time IFD). Analog audio needs snd-hda-phytium; GPU accel still
      needs Glenfly userspace beyond the in-tree arise DRM module.
    ''
  ];
}
