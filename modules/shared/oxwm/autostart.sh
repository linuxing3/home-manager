# Session helpers that DDE normally starts via /etc/xdg/autostart,
# plus tray apps for oxwm's status-bar systray (IME / sound / aTrust).

already_running() {
  pgrep -u "${USER:-$(id -u)}" -x "$1" >/dev/null 2>&1
}

start_bg() {
  local bin=$1
  shift
  if [[ -x $bin ]] || command -v "$bin" >/dev/null 2>&1; then
    if [[ $bin == */* ]]; then
      "$bin" "$@" >/dev/null 2>&1 &
    else
      command "$bin" "$@" >/dev/null 2>&1 &
    fi
  fi
}

# --- Pointer: visible cursor; HDMI is the only live Glenfly output ---
if command -v xsetroot >/dev/null 2>&1; then
  xsetroot -cursor_name left_ptr 2>/dev/null || true
fi
# After a VT pause, XI slaves can stay floating and the core pointer dies.
if command -v xinput >/dev/null 2>&1; then
  while read -r id; do
    [[ "$id" =~ ^[0-9]+$ ]] || continue
    name=$(xinput list --name-only "$id" 2>/dev/null || true)
    if echo "$name" | grep -qiE 'pointer|mouse|XTEST pointer'; then
      xinput reattach "$id" 2 2>/dev/null || true
    else
      xinput reattach "$id" 3 2>/dev/null || true
    fi
  done < <(xinput list --short 2>/dev/null | grep '\[floating slave\]' | sed -n 's/.*id=\([0-9][0-9]*\).*/\1/p')
fi
if command -v xrandr >/dev/null 2>&1; then
  xrandr --output HDMI-1 --primary --auto 2>/dev/null || true
  xrandr --output HDMI-A-1 --primary --auto 2>/dev/null || true
  xrandr --output VGA-1 --off 2>/dev/null || true
fi

# --- Left-handed mouse (swap primary/secondary buttons) ---
# NixOS libinput already sets LeftHanded; a second xinput/xmodmap swap
# would cancel it. Skip keyd/XTEST virtual pointers on UOS.
if [[ ! -e /etc/NIXOS ]] && command -v xinput >/dev/null 2>&1; then
  while read -r id; do
    [[ -n $id ]] || continue
    xinput set-button-map "$id" 3 2 1 4 5 6 7 2>/dev/null || true
  done < <(xinput list --id-only 2>/dev/null | while read -r id; do
    name=$(xinput list --name-only "$id" 2>/dev/null || true)
    echo "$name" | grep -qiE 'keyd|XTEST|Virtual core' && continue
    echo "$name" | grep -qiE 'mouse|touchpad|Optical' && echo "$id"
  done)
fi
if [[ ! -e /etc/NIXOS ]] && command -v xmodmap >/dev/null 2>&1; then
  xmodmap -e 'pointer = 3 2 1 4 5 6 7' 2>/dev/null || true
fi

# --- Session bus helpers (safe under oxwm) ---
# pulseaudio.desktop (UOS). NixOS uses pipewire-pulse.
if ! already_running pulseaudio && ! already_running pipewire-pulse; then
  start_bg start-pulseaudio-x11
fi

# at-spi-dbus-bus.desktop — Nix at-spi-bus-launcher, else UOS libexec.
if command -v at-spi-bus-launcher >/dev/null 2>&1; then
  start_bg at-spi-bus-launcher --launch-immediately
else
  start_bg /usr/lib/at-spi2-core/at-spi-bus-launcher --launch-immediately
fi

# xdg-user-dirs.desktop
start_bg xdg-user-dirs-update

# gnome-keyring-*.desktop (OnlyShowIn=Deepin/Uos on host — start explicitly)
if command -v gnome-keyring-daemon >/dev/null 2>&1; then
  gnome-keyring-daemon --start --components=pkcs11,secrets,ssh >/dev/null 2>&1 &
fi

# --- Input method (fcitx5 + Rime). Sogou is not packaged in nixpkgs. ---
export GTK_IM_MODULE="${GTK_IM_MODULE:-fcitx}"
export QT_IM_MODULE="${QT_IM_MODULE:-fcitx}"
export QT4_IM_MODULE="${QT4_IM_MODULE:-fcitx}"
export XMODIFIERS="${XMODIFIERS:-@im=fcitx}"
export SDL_IM_MODULE="${SDL_IM_MODULE:-fcitx}"
export INPUT_METHOD="${INPUT_METHOD:-fcitx}"

# Nix wrap changes comm to .fcitx5-wrapped; match the real binary.
if pgrep -u "${USER:-$(id -u)}" -f '/bin/fcitx5' >/dev/null 2>&1; then
  command -v fcitx5-remote >/dev/null 2>&1 && fcitx5-remote -x >/dev/null 2>&1 || true
else
  start_bg fcitx5 -d --replace
fi
(
  sleep 2
  command -v fcitx5-remote >/dev/null 2>&1 || exit 0
  fcitx5-remote -x >/dev/null 2>&1 || true
  fcitx5-remote -o >/dev/null 2>&1 || true
) &

# --- Sound tray (DDE uses dock libsound.so; oxwm uses pasystray) ---
if ! already_running pasystray; then
  start_bg pasystray
fi

# --- aTrust tray (DDE: systemd --user aTrustTray.service) ---
if ! pgrep -u "${USER:-$(id -u)}" -f 'aTrustTray' >/dev/null 2>&1; then
  if command -v aTrustTray2 >/dev/null 2>&1; then
    start_bg aTrustTray2
  else
    start_bg /usr/share/sangfor/aTrust/resources/shell/aTrustTrayStart.sh
  fi
fi

# --- Other useful host autostarts that are not Deepin-UI-only ---
start_bg permission_manager_dbus_session_daemon
start_bg /usr/bin/permission_manager_dbus_session_daemon
start_bg deepin-defender-session-daemon
start_bg /usr/bin/deepin-defender-session-daemon
start_bg /usr/lib/geoclue-2.0/demos/agent

# Enterprise / device trays (host binaries on PATH only).
if command -v qaxtray >/dev/null 2>&1; then
  start_bg qaxtray setenv oxwm
fi
if command -v hp-systray >/dev/null 2>&1; then
  start_bg hp-systray -x
fi
if command -v pantum_smclient >/dev/null 2>&1; then
  start_bg pantum_smclient -s
fi

# UDCP session helper (if present)
start_bg /usr/share/udcp/scripts/udcp-session.sh
