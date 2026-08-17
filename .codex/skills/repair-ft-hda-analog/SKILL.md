---
name: repair-ft-hda-analog
description: Use when this Phytium UOS desktop has no sound, PulseAudio default sink is auto_null, analog ALC897/ft-hda profile is off, paplay is silent, or analog-stereo never appears because ALSA front:N is missing.
---

# Repair Phytium ft-hda analog audio

The analog card is Realtek ALC897 on platform `PHYT0006:00` (`ft-hda`, ALSA card `fthda`). HDMI/DP on Glenfly is a separate card and stays off when no HDMI audio is present.

## Diagnose

```sh
export LANG=C LC_ALL=C
aplay -l
pactl list short sinks
pactl info
pactl list cards
amixer -c fthda cget name='Line Out Jack'
aplay -D front:1 /dev/zero
```

Expect sinks to include `alsa_output.platform-PHYT0006_00.stereo-fallback`, not only `auto_null`. `front:1` fails with `Unknown PCM front:1` because `/usr/share/alsa/cards` has no `ft-hda.conf`. PulseAudio `analog-stereo` uses `front:%f` and never probes; `stereo-fallback` uses `hw:%f` and does.

If `Line Out Jack` is `on` but PulseAudio ports say unavailable, restart PulseAudio after forcing the profile. Do not replace UOS `/usr/bin/pulseaudio` with Nix PulseAudio.

## Runtime repair

```sh
pactl set-card-profile alsa_card.platform-PHYT0006_00 output:stereo-fallback
pactl set-sink-port alsa_output.platform-PHYT0006_00.stereo-fallback analog-output-lineout
pactl set-default-sink alsa_output.platform-PHYT0006_00.stereo-fallback
pactl set-sink-mute alsa_output.platform-PHYT0006_00.stereo-fallback 0
paplay /usr/share/sounds/alsa/Front_Center.wav
```

Require the analog sink, active port `analog-output-lineout`, no dummy sink, and `paplay` exit 0.

## Persist

Keep `modules/hardware/ft-hda-audio.nix` imported from the work profile. It writes `~/.config/pulse/default.pa` (includes `/etc/pulse/default.pa`, then forces analog) and a user oneshot `ft-hda-analog.service`. Until Home Manager is switched, write that `default.pa` by hand and restart `pulseaudio.service`.

`module-dconfig-adapter` failing at start is expected without Deepin dconfig D-Bus and is not the analog-silence root cause.

Speakers are rear green line-out. Front headphone jack reports unplugged unless headphones are present.
