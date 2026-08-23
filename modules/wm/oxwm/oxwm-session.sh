# startx / LightDM / xsessions entrypoint for oxwm on UOS + Home Manager.

# Prefer HM / Nix profile tools while keeping host (UOS) binaries available.
export PATH="${HOME}/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/usr/bin:/bin:${PATH:-}"

if [[ -f ${HOME}/.nix-profile/etc/profile.d/hm-session-vars.sh ]]; then
  # shellcheck disable=SC1091
  . "${HOME}/.nix-profile/etc/profile.d/hm-session-vars.sh"
fi

# Sogou / fcitx need host libs; keep their private libs visible.
export LD_LIBRARY_PATH="/opt/apps/com.sogou.sogoupinyin-uos/files/lib:/opt/apps/com.sogou.sogoupinyin-uos/files/lib/qt5/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

export GTK_IM_MODULE="${GTK_IM_MODULE:-fcitx}"
export QT_IM_MODULE="${QT_IM_MODULE:-fcitx}"
export QT4_IM_MODULE="${QT4_IM_MODULE:-fcitx}"
export XMODIFIERS="${XMODIFIERS:-@im=fcitx}"
export SDL_IM_MODULE="${SDL_IM_MODULE:-fcitx}"
export INPUT_METHOD="${INPUT_METHOD:-fcitx}"

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

exec oxwm
