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
  unmuteFtHda = pkgs.writeShellApplication {
    name = "ft-hda-unmute";
    runtimeInputs = [pkgs.coreutils pkgs.gnugrep pkgs.alsa-utils pkgs.python3 pkgs.wireplumber];
    text = ''
      set -eu

      # ALC897 speaker amp is GPIO-gated. snd-hda-phytium leaves all 5
      # GPIOs off, so line-out can be unmuted with PCM running and still
      # be silent. Drive them as outputs high (active-high amp enable).
      apply_codec_hints() {
        local chip dir
        for chip in /sys/class/sound/hwC*/chip_name; do
          [[ -r $chip ]] || continue
          grep -qx ALC897 "$chip" || continue
          dir=$(dirname "$chip")
          printf '%s\n' 'auto_mute = no' 'auto_mic = no' >"$dir/hints" || true
          # Busy if PipeWire already opened the PCM; boot-time start is free.
          echo 1 >"$dir/reconfig" 2>/dev/null || true
        done
      }

      enable_amp_gpio() {
        python3 - <<'PY'
      import ctypes, fcntl, os
      from ctypes import c_uint32, sizeof
      IOC_READ, IOC_WRITE = 2, 1
      def _IOWR(t, n, s):
          return (IOC_READ << 30) | (IOC_WRITE << 30) | (ord(t) << 8) | n | (s << 16)
      class Verb(ctypes.Structure):
          _fields_ = [("verb", c_uint32), ("res", c_uint32)]
      IOCTL = _IOWR("H", 0x11, sizeof(Verb))
      def pack(nid, verb, param):
          return (nid << 24) | (verb << 8) | (param & 0xFF)
      fd = os.open("/dev/snd/hwC1D0", os.O_RDWR)
      def cmd(nid, verb, param=0):
          buf = Verb(pack(nid, verb, param), 0)
          fcntl.ioctl(fd, IOCTL, buf)
          return buf.res
      cmd(0x01, 0x716, 0x1F)  # SET_GPIO_MASK
      cmd(0x01, 0x717, 0x1F)  # SET_GPIO_DIRECTION
      cmd(0x01, 0x715, 0x1F)  # SET_GPIO_DATA
      cmd(0x14, 0x70C, 2)     # SET_EAPD line-out
      cmd(0x1B, 0x70C, 2)     # SET_EAPD headphone
      os.close(fd)
      PY
      }

      keep_speakers() {
        local card
        for card in fthda phytiumhda; do
          if amixer -c "$card" sget Master >/dev/null 2>&1; then
            amixer -c "$card" -q set 'Auto-Mute Mode' Disabled || true
            amixer -c "$card" -q set Master unmute || true
            amixer -c "$card" -q set Front unmute || true
            amixer -c "$card" -q set Headphone unmute 100% || true
            return 0
          fi
        done
        return 1
      }

      unmute_mixer() {
        local card
        for card in fthda phytiumhda; do
          if amixer -c "$card" sget Master >/dev/null 2>&1; then
            amixer -c "$card" -q set 'Auto-Mute Mode' Disabled || true
            amixer -c "$card" -q set Master unmute 80% || true
            amixer -c "$card" -q set Front unmute 100% || true
            amixer -c "$card" -q set Headphone unmute 100% || true
            return 0
          fi
        done
        return 1
      }

      unmute_once() {
        enable_amp_gpio || true
        unmute_mixer
      }

      unmute_sinks() {
        local rundir
        for rundir in /run/user/*; do
          [[ -S "$rundir"/pipewire-0 ]] || continue
          XDG_RUNTIME_DIR=$rundir wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 || true
        done
      }

      unmute_sinks_boot() {
        local rundir
        for rundir in /run/user/*; do
          [[ -S "$rundir"/pipewire-0 ]] || continue
          XDG_RUNTIME_DIR=$rundir wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 || true
          XDG_RUNTIME_DIR=$rundir wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.80 || true
        done
      }

      apply_codec_hints || true

      # WirePlumber ACP reapplies Headphone=0 after the card appears.
      # This host never reaches graphical.target (startx/getty), so a
      # oneshot plus a graphical-target late unit misses the remute.
      for _ in $(seq 1 40); do
        unmute_once || true
        unmute_sinks_boot
        sleep 0.5
      done
      unmute_once || true
      unmute_sinks_boot
      alsactl store || true

      while true; do
        keep_speakers || true
        unmute_sinks
        sleep 10
      done
    '';
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
  boot.extraModprobeConfig = ''
    options snd-hda-phytium power_save=0
  '';

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

  # Type=simple watchdog: ACP remutes Headphone after PipeWire binds, and
  # startx never starts graphical.target so a late oneshot never ran.
  systemd.services.ft-hda-unmute-late.enable = false;
  systemd.services.ft-hda-unmute = {
    description = "Unmute Phytium ft-hda analog mixer";
    after = [
      "sound.target"
      "alsa-restore.service"
    ];
    wants = ["sound.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = "5";
      ExecStart = lib.getExe unmuteFtHda;
    };
  };

  warnings = [
    ''
      phytium-kernel: building Deepin linux-6.6.y from source (large, slow,
      first-time IFD). Analog audio needs snd-hda-phytium; GPU accel still
      needs Glenfly userspace beyond the in-tree arise DRM module.
    ''
  ];
}
