#!/usr/bin/env bash
# nixos-enter for UOS kernel 4.19.
# Upstream nixos-enter runs `unshare --mount-proc`, which fails here with
# EBUSY (设备或资源忙) because systemd has binfmt_misc mounted under /proc.
# Skip that remount; rbind of the host /proc is enough for grub-install.
# shellcheck shell=bash

set -e

if [ -z "$NIXOS_ENTER_REEXEC" ]; then
  export NIXOS_ENTER_REEXEC=1
  extraFlags=""
  if [ "$(id -u)" != 0 ]; then
    extraFlags="-r"
  fi
  exec unshare --fork --mount --uts --propagation private $extraFlags -- "$0" "$@"
else
  mount --make-rprivate /
fi

mountPoint=/mnt
system=/nix/var/nix/profiles/system
command=("$system/sw/bin/bash" "--login")
silent=0

while [ "$#" -gt 0 ]; do
  i="$1"
  shift 1
  case "$i" in
    --root)
      mountPoint="$1"
      shift 1
      ;;
    --system)
      system="$1"
      shift 1
      ;;
    --help)
      echo "usage: $0 [--root DIR] [--system PATH] [--command CMD]"
      exit 0
      ;;
    --command | -c)
      command=("$system/sw/bin/bash" "-c" "$1")
      shift 1
      ;;
    --silent)
      silent=1
      ;;
    --)
      command=("$@")
      break
      ;;
    *)
      echo "$0: unknown option \`$i'" >&2
      exit 1
      ;;
  esac
done

if [[ ! -e $mountPoint/etc/NIXOS ]]; then
  echo "$0: '$mountPoint' is not a NixOS installation" >&2
  exit 126
fi

mkdir -p "$mountPoint/dev" "$mountPoint/sys" "$mountPoint/proc"
chmod 0755 "$mountPoint/dev" "$mountPoint/sys" "$mountPoint/proc"
mount --rbind /dev "$mountPoint/dev"
mount --rbind /sys "$mountPoint/sys"
mount --rbind /proc "$mountPoint/proc"

chroot_add_resolv_conf() {
  local chrootDir="$1" resolvConf="$1/etc/resolv.conf"

  [[ -e /etc/resolv.conf ]] || return 0

  if [[ -L "$resolvConf" ]]; then
    resolvConf="$(readlink "$resolvConf")"
    if [[ "$resolvConf" = /* ]]; then
      resolvConf="$chrootDir$resolvConf"
    else
      resolvConf="$chrootDir/etc/$resolvConf"
    fi
  fi

  if [[ ! -f "$resolvConf" ]]; then
    install -Dm644 /dev/null "$resolvConf" || return 1
  fi

  mount --bind /etc/resolv.conf "$resolvConf"
}

chroot_add_resolv_conf "$mountPoint" || echo "$0: failed to set up resolv.conf" >&2

# Host UOS exports LANG=zh_CN.UTF-8 with LC_* unset. Perl in activation then
# warns. Force C for enter; NixOS glibc may not contain zh_CN until generated.
export LC_ALL=C LANG=C LANGUAGE=C

(
  if [ "$silent" -eq 1 ]; then
    exec 2>/dev/null
  fi

  LOCALE_ARCHIVE="$system/sw/lib/locale/locale-archive" \
    LC_ALL=C LANG=C LANGUAGE=C \
    IN_NIXOS_ENTER=1 chroot "$mountPoint" "$system/activate" 1>&2 || true
  LC_ALL=C LANG=C LANGUAGE=C \
    chroot "$mountPoint" "$system/sw/bin/systemd-tmpfiles" --create --remove -E 2>/dev/null || true
)

unset TMPDIR

# Resolve chroot on the host before touching PATH. Then prepend NixOS bins so
# the inner bash can find mount/grub; leftover UOS PATH entries are harmless.
chroot_bin=$(command -v chroot)
[ -n "$chroot_bin" ] || chroot_bin=/usr/sbin/chroot
export PATH="$system/sw/bin:$system/bin:/run/current-system/sw/bin:/run/current-system/bin:$PATH"

exec "$chroot_bin" "$mountPoint" "${command[@]}"
