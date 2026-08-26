# startx / LightDM / xsessions entrypoint for oxwm on NixOS (and UOS + HM).

# Prefer HM / NixOS tools; keep UOS /usr/bin last for dual-boot.
export PATH="${HOME}/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/run/wrappers/bin:/run/current-system/sw/bin:/etc/profiles/per-user/${USER:-$(id -un)}/bin:/usr/bin:/bin:${PATH:-}"

if [[ -f ${HOME}/.nix-profile/etc/profile.d/hm-session-vars.sh ]]; then
  # shellcheck disable=SC1091
  . "${HOME}/.nix-profile/etc/profile.d/hm-session-vars.sh"
fi

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
export XDG_SESSION_DESKTOP="${XDG_SESSION_DESKTOP:-oxwm}"
export XDG_CURRENT_DESKTOP="${XDG_CURRENT_DESKTOP:-oxwm}"

# startx/getty does not put DISPLAY on the user systemd manager, so
# fcitx5-daemon (WantedBy=graphical-session.target) would start without X11.
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

# st-256color terminfo from Nix ncurses when host terminfo lacks it.
if [[ -z ${TERMINFO_DIRS:-} ]]; then
  for d in "${HOME}/.nix-profile/share/terminfo" /nix/var/nix/profiles/default/share/terminfo; do
    if [[ -d $d ]]; then
      export TERMINFO_DIRS="$d"
      break
    fi
  done
fi

mkdir -p "${HOME}/.config/oxwm"
if [[ -f /etc/oxwm/config.lua ]]; then
  ln -sfn /etc/oxwm/config.lua "${HOME}/.config/oxwm/config.lua"
fi

# Merge Xresources / Xdefaults if present.
if command -v xrdb >/dev/null 2>&1; then
  [[ -f ${HOME}/.Xresources ]] && xrdb -merge "${HOME}/.Xresources" || true
  [[ -f ${HOME}/.Xdefaults ]] && xrdb -merge "${HOME}/.Xdefaults" || true
fi

# oxwm has no root cursor of its own. Glenfly also advertises a dummy VGA-1
# that X promotes to primary, which parks the pointer off the HDMI screen.
if command -v xrandr >/dev/null 2>&1; then
  xrandr --output HDMI-1 --primary --auto 2>/dev/null || true
  xrandr --output HDMI-A-1 --primary --auto 2>/dev/null || true
  xrandr --output VGA-1 --off 2>/dev/null || true
fi
if command -v xsetroot >/dev/null 2>&1; then
  xsetroot -cursor_name left_ptr || true
fi

# HDMI may still be on tty2 (getty/startx failed, serial/Cursor login).
# X on vt1 is paused until this VT is foreground.
sudo -n chvt 1 >/dev/null 2>&1 || true

exec oxwm
