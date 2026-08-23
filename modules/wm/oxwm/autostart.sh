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

# --- Left-handed mouse (swap primary/secondary buttons) ---
if command -v xinput >/dev/null 2>&1; then
  while read -r id; do
    [[ -n $id ]] || continue
    xinput set-button-map "$id" 3 2 1 4 5 6 7 2>/dev/null || true
  done < <(xinput list --id-only 2>/dev/null | while read -r id; do
    name=$(xinput list --name-only "$id" 2>/dev/null || true)
    echo "$name" | grep -qiE 'pointer|mouse|touchpad|Optical' && echo "$id"
  done)
fi
if command -v xmodmap >/dev/null 2>&1; then
  xmodmap -e 'pointer = 3 2 1 4 5 6 7' 2>/dev/null || true
fi

# --- DDE Initialization-phase services (safe under oxwm) ---
# pulseaudio.desktop
if ! already_running pulseaudio; then
  start_bg start-pulseaudio-x11
fi

# at-spi-dbus-bus.desktop
start_bg /usr/lib/at-spi2-core/at-spi-bus-launcher --launch-immediately

# xdg-user-dirs.desktop
start_bg xdg-user-dirs-update

# gnome-keyring-*.desktop (OnlyShowIn=Deepin/Uos on host — start explicitly)
if command -v gnome-keyring-daemon >/dev/null 2>&1; then
  gnome-keyring-daemon --start --components=pkcs11,secrets,ssh >/dev/null 2>&1 &
fi

# --- Input method (fcitx + Sogou); keep host libs ahead of Nix ---
export GTK_IM_MODULE="${GTK_IM_MODULE:-fcitx}"
export QT_IM_MODULE="${QT_IM_MODULE:-fcitx}"
export QT4_IM_MODULE="${QT4_IM_MODULE:-fcitx}"
export XMODIFIERS="${XMODIFIERS:-@im=fcitx}"
export SDL_IM_MODULE="${SDL_IM_MODULE:-fcitx}"
export INPUT_METHOD="${INPUT_METHOD:-fcitx}"
export LD_LIBRARY_PATH="/opt/apps/com.sogou.sogoupinyin-uos/files/lib:/opt/apps/com.sogou.sogoupinyin-uos/files/lib/qt5/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

# Ensure Sogou fcitx addon stays enabled (user override can disable it)
mkdir -p "${HOME}/.config/fcitx/addon"
printf '%s\n' '[Addon]' 'Enabled=True' >"${HOME}/.config/fcitx/addon/fcitx-sogoupinyinuos.conf"
if [[ -f ${HOME}/.config/fcitx/profile ]]; then
  sed -i 's/^IMName=.*/IMName=sogoupinyinuos/' "${HOME}/.config/fcitx/profile" || true
fi

start_bg /opt/apps/com.sogou.sogoupinyin-uos/files/bin/sogouImeService-uos
start_bg /opt/apps/com.sogou.sogoupinyin-uos/files/bin/sogouImeService-watchdog-uos

if ! already_running fcitx; then
  # Prefer system fcitx so Sogou plugin can resolve libfcitx-core symbols.
  if [[ -x /usr/bin/fcitx ]]; then
    /usr/bin/fcitx -rd >/dev/null 2>&1 &
  else
    start_bg fcitx-helper
  fi
  (
    sleep 2
    command -v fcitx-remote >/dev/null 2>&1 || exit 0
    fcitx-remote -o >/dev/null 2>&1 || true
    fcitx-remote -s sogoupinyinuos >/dev/null 2>&1 || true
  ) &
fi

# --- Sound tray (DDE uses dock libsound.so; oxwm uses pasystray) ---
if ! already_running pasystray; then
  start_bg pasystray
fi

# --- aTrust tray (DDE: systemd --user aTrustTray.service) ---
if ! pgrep -u "${USER:-$(id -u)}" -f 'aTrustTray' >/dev/null 2>&1; then
  start_bg /usr/share/sangfor/aTrust/resources/shell/aTrustTrayStart.sh
fi

# --- Other useful host autostarts that are not Deepin-UI-only ---
start_bg /usr/bin/permission_manager_dbus_session_daemon
start_bg /usr/bin/deepin-defender-session-daemon
start_bg /usr/lib/geoclue-2.0/demos/agent

# Enterprise / device trays that also autostart under DDE
start_bg /opt/apps/com.qianxin.qaxsafe/files/qaxtray setenv oxwm
start_bg /opt/hp/hplip/bin/systray.py -x
start_bg /opt/apps/com.pantum.pantum/files/bin/pantum_smclient -s

# UDCP session helper (if present)
start_bg /usr/share/udcp/scripts/udcp-session.sh
