# dwm session for greetd / startx. Autostart matches oxwm (IME, tray, theme).

export PATH="${HOME}/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/run/wrappers/bin:/run/current-system/sw/bin:/etc/profiles/per-user/${USER:-$(id -un)}/bin:/usr/bin:/bin:${PATH:-}"

if [[ -f ${HOME}/.nix-profile/etc/profile.d/hm-session-vars.sh ]]; then
  # shellcheck disable=SC1091
  . "${HOME}/.nix-profile/etc/profile.d/hm-session-vars.sh"
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
export XDG_SESSION_DESKTOP="${XDG_SESSION_DESKTOP:-dwm}"
export XDG_CURRENT_DESKTOP="${XDG_CURRENT_DESKTOP:-dwm}"

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
  st-theme auto >/dev/null 2>&1 || true
fi
if command -v stylix-theme >/dev/null 2>&1; then
  stylix-theme auto >/dev/null 2>&1 || true
fi
if command -v oxwm-autostart >/dev/null 2>&1; then
  oxwm-autostart >/dev/null 2>&1 || true
fi

pkill -x dwm-status >/dev/null 2>&1 || true
dwm-status >/dev/null 2>&1 &

pkill -x trayer >/dev/null 2>&1 || true
trayer --edge top --align right --widthtype request --height 22 \
  --transparent true --alpha 0 --tint 0x1a1b26 \
  --SetDockType true --SetPartialStrut true --padding 4 \
  >/dev/null 2>&1 &

# Super+Shift+Q (quit) exits 0 and leaves X; Super+Shift+R (pkill dwm) is non-zero and loops.
while true; do
  dwm && break
done
