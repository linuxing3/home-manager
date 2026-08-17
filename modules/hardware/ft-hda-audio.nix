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
    runtimeInputs = [pkgs.coreutils];
    text = ''
      set -euo pipefail

      pactl=/usr/bin/pactl
      amixer=/usr/bin/amixer

      if [[ ! -x $pactl ]]; then
        echo "fix-ft-hda-analog: /usr/bin/pactl is missing" >&2
        exit 1
      fi

      for _ in $(${pkgs.coreutils}/bin/seq 1 20); do
        if "$pactl" list cards short 2>/dev/null | ${pkgs.gnugrep}/bin/grep -Fq ${lib.escapeShellArg analogCard}; then
          break
        fi
        sleep 0.25
      done

      "$pactl" set-card-profile ${lib.escapeShellArg analogCard} output:stereo-fallback || true
      "$pactl" set-sink-port ${lib.escapeShellArg analogSink} ${lib.escapeShellArg analogPort} || true
      "$pactl" set-default-sink ${lib.escapeShellArg analogSink} || true
      "$pactl" set-sink-mute ${lib.escapeShellArg analogSink} 0 || true

      if [[ -x $amixer ]]; then
        "$amixer" -c fthda -q set Master unmute 80% || true
        "$amixer" -c fthda -q set Front unmute 100% || true
        "$amixer" -c fthda -q set Headphone unmute 100% || true
      fi
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
    .fail
  '';

  systemd.user.services.ft-hda-analog = {
    Unit = {
      Description = "Force Phytium ft-hda analog line-out";
      After = ["pulseaudio.service"];
      Wants = ["pulseaudio.service"];
    };
    Service = {
      Type = "oneshot";
      ExecStart = lib.getExe fixFtHdaAnalog;
      RemainAfterExit = true;
      # UOS systemd 241 rejects PrivateDevices in user units.
      NoNewPrivileges = true;
      PrivateTmp = true;
      RestrictAddressFamilies = ["AF_UNIX"];
      UMask = "0077";
    };
    Install.WantedBy = ["default.target"];
  };
}
