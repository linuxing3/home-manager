# Hardware copied from the live UOS Phytium desktop (Designers-PC).
# Glenfly arise and ft-hda are UOS-patched; mainline 6.18 uses modesetting +
# snd_hda_intel / snd_hda_phytium when those modules exist.
{
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
  boot.blacklistedKernelModules = ["r8168"];
  boot.extraModprobeConfig = ''
    options snd-hda-intel enable_msi=1
  '';
  boot.kernelParams = [
    "video=HDMI-A-1:1920x1080@60"
  ];

  hardware.graphics.enable = true;
  hardware.enableRedistributableFirmware = true;

  # Glenfly Arise1020 (PCI 6766:3d02). UOS uses proprietary arise_drv;
  # NixOS has no arise package, so modesetting is the KMS fallback.
  services.xserver.videoDrivers = ["modesetting"];
  services.xserver.exportConfiguration = true;
  environment.etc."X11/xorg.conf.d/10-glenfly.conf".text = ''
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
