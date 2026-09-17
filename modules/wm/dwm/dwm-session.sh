# dwm session for greetd / startx. Autostart matches oxwm (IME, tray, theme).

# writeShellApplication puts the closure's dwm and helpers first. Keep them
# ahead of Home Manager so greetd cannot accidentally launch a stale profile
# binary, while still exposing the user's applications to dwm keybindings.
export PATH="${PATH:-}:${HOME}/.nix-profile/bin:/etc/profiles/per-user/${USER:-$(id -un)}/bin:/nix/var/nix/profiles/default/bin:/run/wrappers/bin:/run/current-system/sw/bin:/usr/bin:/bin"

if [[ -z ${__HM_SESS_VARS_SOURCED:-} && -f ${HOME}/.nix-profile/etc/profile.d/hm-session-vars.sh ]]; then
  # Home Manager emits optional-variable expansions that are not nounset-safe.
  # writeShellApplication enables nounset, while greetd starts with a sparse
  # environment, so source the generated file with nounset temporarily off.
  set +u
  # shellcheck disable=SC1091
  . "${HOME}/.nix-profile/etc/profile.d/hm-session-vars.sh"
  set -u
fi

export LANG="${LANG:-C.UTF-8}"
export LC_CTYPE="${LC_CTYPE:-$LANG}"

export GTK_IM_MODULE="${GTK_IM_MODULE:-fcitx}"
export QT_IM_MODULE="${QT_IM_MODULE:-fcitx}"
export QT4_IM_MODULE="${QT4_IM_MODULE:-fcitx}"
export XMODIFIERS="${XMODIFIERS:-@im=fcitx}"
export SDL_IM_MODULE="${SDL_IM_MODULE:-fcitx}"
export INPUT_METHOD="${INPUT_METHOD:-fcitx}"

# X11 only. Drop leftover niri/wayland vars so Ozone apps (Brave) use DISPLAY.
unset WAYLAND_DISPLAY
unset NIXOS_OZONE_WL
export XDG_SESSION_TYPE=x11
export XDG_SESSION_DESKTOP=dwm
export XDG_CURRENT_DESKTOP=dwm

if command -v systemctl >/dev/null 2>&1; then
  systemctl --user unset-environment WAYLAND_DISPLAY NIXOS_OZONE_WL \
    >/dev/null 2>&1 || true
  systemctl --user import-environment DISPLAY XAUTHORITY XDG_SESSION_TYPE \
    XDG_SESSION_DESKTOP XDG_CURRENT_DESKTOP \
    GTK_IM_MODULE QT_IM_MODULE QT4_IM_MODULE XMODIFIERS SDL_IM_MODULE INPUT_METHOD \
    >/dev/null 2>&1 || true
fi
if command -v dbus-update-activation-environment >/dev/null 2>&1; then
  dbus-update-activation-environment --systemd DISPLAY XAUTHORITY \
    WAYLAND_DISPLAY NIXOS_OZONE_WL \
    XDG_SESSION_TYPE XDG_SESSION_DESKTOP XDG_CURRENT_DESKTOP \
    GTK_IM_MODULE QT_IM_MODULE QT4_IM_MODULE XMODIFIERS SDL_IM_MODULE INPUT_METHOD \
    >/dev/null 2>&1 || true
fi

if [[ -z ${TERMINFO_DIRS:-} ]]; then
  for d in "${HOME}/.nix-profile/share/terminfo" /nix/var/nix/profiles/default/share/terminfo; do
    if [[ -d $d ]]; then
      export TERMINFO_DIRS="$d"
      break
    fi
  done
fi

if command -v xrdb >/dev/null 2>&1; then
  [[ -f ${HOME}/.Xresources ]] && xrdb -merge "${HOME}/.Xresources" || true
  [[ -f ${HOME}/.Xdefaults ]] && xrdb -merge "${HOME}/.Xdefaults" || true
fi

if command -v xrandr >/dev/null 2>&1; then
  xrandr --output HDMI-1 --primary --auto 2>/dev/null || true
  xrandr --output HDMI-A-1 --primary --auto 2>/dev/null || true
  xrandr --output VGA-1 --off 2>/dev/null || true
fi
if command -v xsetroot >/dev/null 2>&1; then
  xsetroot -cursor_name left_ptr || true
fi

if command -v st-theme >/dev/null 2>&1; then
  st-theme >/dev/null 2>&1 || true
fi
if command -v stylix-theme >/dev/null 2>&1; then
  stylix-theme >/dev/null 2>&1 || true
fi
if command -v oxwm-autostart >/dev/null 2>&1; then
  oxwm-autostart >/dev/null 2>&1 || true
fi
if command -v theme-switch >/dev/null 2>&1; then
  theme-switch auto >/dev/null 2>&1 || true
fi
if [[ -f ${HOME}/.fehbg-stylix ]]; then
  sh "${HOME}/.fehbg-stylix" >/dev/null 2>&1 || true
fi

state_dir="${XDG_STATE_HOME:-${HOME}/.local/state}/dwm"
mkdir -p "$state_dir"
session_log="$state_dir/session.log"

cleanup() {
  [[ -n ${status_pid:-} ]] && kill "$status_pid" >/dev/null 2>&1 || true
  [[ -n ${trayer_pid:-} ]] && kill "$trayer_pid" >/dev/null 2>&1 || true
}
trap cleanup EXIT
trap 'exit 0' HUP INT TERM

pkill -x dwm-status >/dev/null 2>&1 || true
dwm-status >>"$session_log" 2>&1 &
status_pid=$!

pkill -x trayer >/dev/null 2>&1 || true
trayer --edge top --align right --widthtype request --height 22 \
  --transparent true --alpha 0 --tint 0x010101 \
  --SetDockType true --SetPartialStrut true --padding 4 \
  >>"$session_log" 2>&1 &
trayer_pid=$!

# Super+Shift+Q (quit) exits 0 and leaves X; Super+Shift+R (pkill dwm) is non-zero and loops.
while true; do
  set +e
  dwm 2>>"$session_log"
  dwm_status=$?
  set -e
  if ((dwm_status == 0)); then
    break
  fi
  printf '%s dwm exited with status %d; restarting in 1 second\n' \
    "$(date --iso-8601=seconds)" "$dwm_status" >>"$session_log"
  sleep 1
done
