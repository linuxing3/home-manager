{
  pkgs,
  lib,
  ...
}: let
  analogCard = "alsa_card.platform-PHYT0006_00";
  analogSink = "alsa_output.platform-PHYT0006_00.stereo-fallback";
  analogPort = "analog-output-lineout";

  fixFtHdaAnalog = pkgs.writeShellApplication {
    name = "fix-ft-hda-analog";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gnugrep
      pkgs.alsa-utils
      pkgs.wireplumber
      pkgs.pulseaudio
    ];
    text = ''
      set -euo pipefail

      # NixOS user units omit /usr/bin; UOS pactl lives there.
      PATH="$PATH:/run/current-system/sw/bin:/usr/bin"

      pactl=$(command -v pactl || true)
      wpctl=$(command -v wpctl || true)
      amixer=$(command -v amixer || true)

      if [[ -z $pactl && -z $wpctl && -z $amixer ]]; then
        echo "fix-ft-hda-analog: pactl, wpctl, and amixer are missing" >&2
        exit 1
      fi

      analog_visible() {
        local out=""
        if [[ -n $pactl ]]; then
          out=$("$pactl" list cards short 2>/dev/null || true)
          [[ $out == *platform-PHYT0006* ]] && return 0
        fi
        if [[ -n $wpctl ]]; then
          out=$("$wpctl" status 2>/dev/null || true)
          [[ $out == *PHYT0006* || $out == *ft-hda* || $out == *ALC897* || $out == *"Phytium ft-hda analog"* ]] && return 0
        fi
        return 1
      }

      default_sink_ready() {
        local vol=""
        if [[ -n $wpctl ]]; then
          vol=$("$wpctl" get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || true)
          [[ $vol == Volume:* ]] && return 0
        fi
        if [[ -n $pactl ]] && "$pactl" get-sink-mute @DEFAULT_SINK@ >/dev/null 2>&1; then
          return 0
        fi
        return 1
      }

      unmute_mixer() {
        local card
        [[ -n $amixer ]] || return 0
        for card in fthda phytiumhda; do
          if "$amixer" -c "$card" sget Master >/dev/null 2>&1; then
            "$amixer" -c "$card" -q set 'Auto-Mute Mode' Disabled || true
            "$amixer" -c "$card" -q set Master unmute || true
            "$amixer" -c "$card" -q set Front unmute || true
            "$amixer" -c "$card" -q set Headphone unmute 100% || true
            return 0
          fi
        done
        return 1
      }

      boot_mixer() {
        local card
        [[ -n $amixer ]] || return 0
        for card in fthda phytiumhda; do
          if "$amixer" -c "$card" sget Master >/dev/null 2>&1; then
            "$amixer" -c "$card" -q set 'Auto-Mute Mode' Disabled || true
            "$amixer" -c "$card" -q set Master unmute 80% || true
            "$amixer" -c "$card" -q set Front unmute 100% || true
            "$amixer" -c "$card" -q set Headphone unmute 100% || true
            return 0
          fi
        done
        return 1
      }

      for _ in $(seq 1 80); do
        if analog_visible && default_sink_ready; then
          break
        fi
        boot_mixer || true
        sleep 0.25
      done

      if ! analog_visible || ! default_sink_ready; then
        echo "fix-ft-hda-analog: analog sink not ready yet" >&2
        boot_mixer || true
        exit 1
      fi

      if [[ -n $pactl ]]; then
        "$pactl" set-card-profile ${lib.escapeShellArg analogCard} output:stereo-fallback || true
        "$pactl" set-sink-port ${lib.escapeShellArg analogSink} ${lib.escapeShellArg analogPort} || true
        "$pactl" set-default-sink ${lib.escapeShellArg analogSink} || true
        "$pactl" set-sink-mute ${lib.escapeShellArg analogSink} 0 || true
        "$pactl" set-sink-volume ${lib.escapeShellArg analogSink} 80% || true
      fi

      if [[ -n $wpctl ]]; then
        "$wpctl" set-mute @DEFAULT_AUDIO_SINK@ 0 || true
        "$wpctl" set-volume @DEFAULT_AUDIO_SINK@ 0.80 || true
      fi

      boot_mixer || true

      # ACP reapplies mixer defaults after the profile binds; rewrite once more.
      sleep 1
      if [[ -n $pactl ]]; then
        "$pactl" set-sink-port ${lib.escapeShellArg analogSink} ${lib.escapeShellArg analogPort} || true
        "$pactl" set-sink-mute ${lib.escapeShellArg analogSink} 0 || true
      fi
      if [[ -n $wpctl ]]; then
        "$wpctl" set-mute @DEFAULT_AUDIO_SINK@ 0 || true
      fi
      boot_mixer || true

      # ACP remutes Headphone after this oneshot used to exit. Keep the
      # analog path rewritten for the life of the session.
      while true; do
        sleep 10
        if [[ -n $pactl ]]; then
          "$pactl" set-sink-port ${lib.escapeShellArg analogSink} ${lib.escapeShellArg analogPort} || true
          "$pactl" set-sink-mute ${lib.escapeShellArg analogSink} 0 || true
        fi
        if [[ -n $wpctl ]]; then
          "$wpctl" set-mute @DEFAULT_AUDIO_SINK@ 0 || true
        fi
        unmute_mixer || true
      done
    '';
  };
in {
  home.packages = [fixFtHdaAnalog];

  xdg.configFile."pulse/default.pa".text = ''
    .include /etc/pulse/default.pa

    # Phytium ft-hda has no ALSA cards/ft-hda.conf, so analog-stereo
    # (front:N) never probes. Keep the hw: stereo-fallback profile on
    # rear line-out even when jack sense is late or empty at login.
    .nofail
    set-card-profile ${analogCard} output:stereo-fallback
    set-sink-port ${analogSink} ${analogPort}
    set-default-sink ${analogSink}
    set-sink-mute ${analogSink} 0
    set-sink-volume ${analogSink} 80%
    .fail
  '';

  systemd.user.services.ft-hda-analog = {
    Unit = {
      Description = "Force Phytium ft-hda analog line-out";
      After = ["pipewire-pulse.service" "wireplumber.service" "pulseaudio.service"];
      Wants = ["pipewire-pulse.service"];
    };
    Service = {
      Type = "simple";
      ExecStart = lib.getExe fixFtHdaAnalog;
      Restart = "always";
      RestartSec = "2s";
      # UOS systemd 241 rejects PrivateDevices in user units.
      NoNewPrivileges = true;
      PrivateTmp = true;
      RestrictAddressFamilies = ["AF_UNIX"];
      UMask = "0077";
    };
    Install.WantedBy = ["default.target"];
  };
}
