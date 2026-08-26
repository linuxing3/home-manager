---
name: repair-ft-hda-analog
description: Use when this Phytium UOS or NixOS desktop has no sound, speakers stay mute, PulseAudio/PipeWire default sink is auto_null, analog ALC897/ft-hda profile is off, paplay is silent, Auto-Mute Mode is Enabled, or analog-stereo never appears because ALSA front:N is missing.
---

# Repair Phytium ft-hda analog audio

The analog card is Realtek ALC897 on platform `PHYT0006:00` (`ft-hda`, ALSA card `fthda`). HDMI/DP on Glenfly is a separate card and stays off when no HDMI audio is present.

## Diagnose

```sh
export LANG=C LC_ALL=C
aplay -l
wpctl status
pactl list short sinks
amixer -c fthda sget Master
amixer -c fthda sget 'Auto-Mute Mode'
amixer -c fthda cget name='Line Out Jack'
```

Expect sinks to include `alsa_output.platform-PHYT0006_00.stereo-fallback`, not only `auto_null`. `front:1` fails with `Unknown PCM front:1` because there is no `cards/ft-hda.conf` unless NixOS wrote `/etc/alsa/cards/ft-hda.conf`. PulseAudio `analog-stereo` uses `front:%f` and never probes; `stereo-fallback` uses `hw:%f` and does.

Silence with PipeWire already on analog is usually ALSA **Auto-Mute Mode=Enabled** plus **Headphone** volume 0. WirePlumber ACP reapplies those defaults after login; software mute on the sink can be off while speakers stay dead. Do not replace UOS `/usr/bin/pulseaudio` with Nix PulseAudio.

## Runtime repair

```sh
amixer -c fthda set 'Auto-Mute Mode' Disabled
amixer -c fthda set Master unmute 80%
amixer -c fthda set Front unmute 100%
amixer -c fthda set Headphone unmute 100%
wpctl set-mute @DEFAULT_AUDIO_SINK@ 0
wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.80
pactl set-card-profile alsa_card.platform-PHYT0006_00 output:stereo-fallback
pactl set-sink-port alsa_output.platform-PHYT0006_00.stereo-fallback analog-output-lineout
pactl set-default-sink alsa_output.platform-PHYT0006_00.stereo-fallback
pw-play /usr/share/sounds/alsa/Front_Center.wav || paplay /usr/share/sounds/alsa/Front_Center.wav
```

Require the analog sink, active port `analog-output-lineout`, Auto-Mute Disabled, Master/Front unmuted, and `pw-play`/`paplay` exit 0.

## Persist

NixOS phytium host: `nixos/phytium-kernel.nix` `ft-hda-unmute.service` is a `multi-user.target` watchdog (GPIO/EAPD, Headphone unmute, `alsactl store`). This machine uses startx/getty, so `graphical.target` stays inactive and must not own unmute. `nixos/hardware-host.nix` keeps ALSA persistence and WirePlumber `stereo-fallback` + `api.acp.auto-port=false`. Rebuild `.#nvme-p6-phytium`.

Home Manager: `modules/hardware/ft-hda-audio.nix` waits for the analog sink, forces line-out, and keeps rewriting the mixer while the session is up. Until Home Manager is switched, run the runtime repair and `systemctl --user restart ft-hda-analog.service`.

`module-dconfig-adapter` failing at start is expected without Deepin dconfig D-Bus and is not the analog-silence root cause.

Speakers are rear green line-out. Front headphone jack reports unplugged unless headphones are present.
