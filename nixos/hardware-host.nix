# Hardware copied from the live UOS Phytium desktop (Designers-PC).
#
# UOS 4.19.0-arm64-desktop: proprietary arise_pro + built-in ft-hda
# (CONFIG_SND_HDA_PHYTIUM). Those .ko files will not load on mainline.
#
# Default NixOS profile (sda): mainline 6.18 — modesetting KMS +
# snd_hda_intel HDMI only. No analog ft-hda, no Glenfly DRM.
#
# Opt-in vendor kernel (sda-phytium): Deepin linux-6.6.y via
# phytium-kernel.nix — snd-hda-phytium + in-tree arise DRM. See
# kernel-phytium.nix. Prefer 6.6.y over EOL/UOS-K5.10-LTS.
{pkgs, ...}: {
  boot.initrd.availableKernelModules = [
    "nvme"
    "ahci"
    "xhci_pci"
    "usbhid"
    "usb_storage"
    "sd_mod"
    "r8169"
  ];
  boot.kernelModules = [
    "r8169"
    "snd_hda_intel"
    "snd_hda_codec_hdmi"
  ];
  # Zhaoxin UHCI at 0d:10.x hard-hangs Deepin 6.6.152 ("host controller
  # process error"). KeyVault + HID belong on xHCI 0d:12.0 — plug those into
  # USB3 ports. Cmdline blacklist covers initrd; module blacklist covers late boot.
  boot.blacklistedKernelModules = [
    "r8168"
    "uhci_hcd"
  ];
  boot.extraModprobeConfig = ''
    options snd-hda-intel enable_msi=1
  '';
  boot.kernelParams = [
    "video=HDMI-A-1:1920x1080@60"
    # Glenfly exposes a dummy VGA connector; X made it primary and the
    # pointer never appeared on HDMI. Disable it at KMS.
    "video=VGA-1:d"
    "modprobe.blacklist=uhci_hcd"
  ];

  hardware.graphics.enable = true;
  hardware.enableRedistributableFirmware = true;

  # Glenfly Arise1020 (PCI 6766:3d02). UOS uses proprietary arise_drv;
  # NixOS has no arise package, so modesetting is the KMS fallback.
  services.xserver.videoDrivers = ["modesetting"];
  services.xserver.exportConfiguration = true;
  # 10-glenfly.conf's Device is a GPUDevice; the screen uses Device-modesetting[0].
  # SWcursor must be on that device or the pointer stays invisible (llvmpipe HW cursor).
  services.xserver.deviceSection = ''
    Option "SWcursor" "on"
    Option "HWCursor" "off"
  '';
  environment.etc."X11/xorg.conf.d/10-glenfly.conf".text = ''
    Section "OutputClass"
        Identifier "glenfly-arise"
        MatchDriver "arise"
        Driver "modesetting"
    EndSection

    # Apply to Device-modesetting[0] as well as the named Glenfly Device.
    Section "OutputClass"
        Identifier "modesetting-swcursor"
        MatchDriver "modesetting"
        Option "SWcursor" "on"
    EndSection

    Section "Monitor"
        Identifier "VGA-1"
        Option "Ignore" "true"
        Option "Enable" "false"
    EndSection

    Section "Monitor"
        Identifier "HDMI-1"
        Option "Primary" "true"
        Option "PreferredMode" "1920x1080"
    EndSection

    Section "Device"
        Identifier "Glenfly Arise1020"
        Driver "modesetting"
        BusID "PCI:1:0:0"
        Option "AccelMethod" "glamor"
        Option "PageFlip" "on"
        # HW cursor is invisible on arise + modesetting/llvmpipe.
        Option "SWcursor" "on"
        Option "HWCursor" "off"
    EndSection
  '';

  # Analog: platform PHYT0006:00 ft-hda / ALC897 (UOS card fthda).
  # HDMI: PCI 01:00.1 snd_hda_intel (keep off as default).
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    wireplumber.enable = true;
    wireplumber.extraConfig."51-fthda-analog" = {
      "monitor.alsa.rules" = [
        {
          matches = [
            {"device.name" = "~alsa_card.platform-PHYT0006.*";}
          ];
          actions.update-props = {
            "device.profile" = "output:stereo-fallback";
            "device.description" = "Phytium ft-hda analog";
            "api.acp.auto-profile" = false;
            "api.acp.auto-port" = false;
            "session.suspend-timeout-seconds" = 0;
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
  };

  # analog-stereo uses front:%f; UOS has no cards/ft-hda.conf so it never probes.
  environment.systemPackages = [pkgs.alsa-utils];
  hardware.alsa.enablePersistence = true;
  # Mixer watchdog (GPIO/EAPD + Headphone unmute) lives in phytium-kernel.nix
  # as ft-hda-unmute.service. This host uses startx, so graphical.target
  # never starts and cannot own that persist.

  environment.etc."alsa/cards/ft-hda.conf".text = ''
    <confdir:pcm/front.conf>
    ft-hda.pcm.front.0 {
        @args [ CARD ]
        @args.CARD { type string }
        type hw
        card $CARD
        device 0
    }
  '';

  # Wired LAN on enp11s0 (Realtek RTL8111/8168, UOS r8168 → NixOS r8169).
  networking.useDHCP = false;
  networking.networkmanager.enable = true;
  networking.networkmanager.ensureProfiles.profiles.lan = {
    connection = {
      id = "lan";
      type = "ethernet";
      interface-name = "enp11s0";
      autoconnect = true;
    };
    ethernet = {
      mac-address = "00:23:81:67:a7:ce";
    };
    ipv4 = {
      method = "manual";
      address1 = "10.10.30.11/24,10.10.30.1";
      dns = "8.8.8.8;1.1.1.1;";
    };
    ipv6 = {
      method = "auto";
    };
  };
}
