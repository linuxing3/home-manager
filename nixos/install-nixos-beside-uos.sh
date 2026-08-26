#!/usr/bin/env bash
# Interactive helper for NixOS beside UOS on /dev/sda.
# Never formats watermelon (sda3), banana (sda4), or nvme0n1.

set -euo pipefail

readonly program_name="install-nixos-beside-uos"
readonly script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
readonly repo_root="$(CDPATH= cd -- "${script_dir}/.." && pwd)"
readonly sda_by_id="ata-WDC_WD10EARZ-22C5XB0_WD-WX22D657N28N"
# Token present in lsblk MODEL (WDC_WD10EARZ-22C5XB0) and sysfs (WDC WD10EARZ-22C).
readonly expected_model_token="WD10EARZ"
readonly root_mnt="${NIXOS_INSTALL_ROOT:-/mnt}"
readonly flake_uri="${repo_root}#sda"
readonly nvme_guard="nvme0n1"

use_color=0
[[ -t 1 && -z "${NO_COLOR:-}" ]] && use_color=1

if ((use_color)); then
  c_reset=$'\033[0m'
  c_bold=$'\033[1m'
  c_dim=$'\033[2m'
  c_cyan=$'\033[36m'
  c_green=$'\033[32m'
  c_yellow=$'\033[33m'
  c_red=$'\033[31m'
  c_blue=$'\033[34m'
else
  c_reset="" c_bold="" c_dim="" c_cyan="" c_green="" c_yellow="" c_red="" c_blue=""
fi

die() {
  printf '%s%s: %s%s\n' "$c_red" "$program_name" "$*" "$c_reset" >&2
  exit 1
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "missing command: $1"
}

nix_user_home() {
  if [[ -n "${SUDO_USER:-}" ]]; then
    getent passwd "$SUDO_USER" | cut -d: -f6
  else
    printf '%s\n' "${HOME}"
  fi
}

nix_bin_dirs() {
  printf '%s\n' \
    "/nix/var/nix/profiles/default/bin" \
    "$(nix_user_home)/.nix-profile/bin" \
    "/root/.nix-profile/bin" \
    "/run/current-system/sw/bin"
}

root_path() {
  local dirs="" d
  while IFS= read -r d; do
    [[ -d "$d" ]] && dirs="${dirs}${d}:"
  done < <(nix_bin_dirs)
  printf '%s/usr/sbin:/usr/bin:/sbin:/bin\n' "$dirs"
}

nix_bin() {
  local d
  while IFS= read -r d; do
    if [[ -x "${d}/nix" ]]; then
      printf '%s\n' "${d}/nix"
      return 0
    fi
  done < <(nix_bin_dirs)
  command -v nix 2>/dev/null || true
}

nixos_install_bin() {
  local d bin
  while IFS= read -r d; do
    bin="${d}/nixos-install"
    if [[ -x "$bin" ]]; then
      printf '%s\n' "$bin"
      return 0
    fi
  done < <(nix_bin_dirs)
  command -v nixos-install 2>/dev/null || true
}

as_root() {
  local path
  path=$(root_path)
  if [[ "$(id -u)" -eq 0 ]]; then
    env PATH="$path" "$@"
  else
    sudo env PATH="$path" "$@"
  fi
}

heading() {
  printf '\n%s╭─ %s%s\n' "$c_cyan$c_bold" "$1" "$c_reset"
}

item() {
  printf '%s│  %s%s\n' "$c_cyan" "$1" "$c_reset"
}

ok() { printf '%s│  ok  %s%s\n' "$c_green" "$1" "$c_reset"; }
warn() { printf '%s│  !!  %s%s\n' "$c_yellow" "$1" "$c_reset"; }
bad() { printf '%s│  xx  %s%s\n' "$c_red" "$1" "$c_reset"; }
note() { printf '%s│     %s%s\n' "$c_dim" "$1" "$c_reset"; }

prompt_choice() {
  local prompt=$1 default_choice=$2 answer
  printf '%s╰─ %s [%s]: %s' "$c_cyan$c_bold" "$prompt" "$default_choice" "$c_reset"
  IFS= read -r answer || true
  printf '%s\n' "${answer:-$default_choice}"
}

confirm() {
  local prompt=$1 expected=${2:-yes}
  local answer
  printf '%s╰─ %s type %s: %s' "$c_yellow$c_bold" "$prompt" "$expected" "$c_reset"
  IFS= read -r answer || true
  [[ "$answer" == "$expected" ]]
}

resolve_sda() {
  local by_id="/dev/disk/by-id/${sda_by_id}"
  if [[ -b "$by_id" ]]; then
    readlink -f "$by_id"
    return
  fi
  if [[ -b /dev/sda ]]; then
    warn "by-id ${sda_by_id} missing; falling back to /dev/sda"
    printf '%s\n' /dev/sda
    return
  fi
  die "cannot find ${sda_by_id} or /dev/sda"
}

part() {
  local disk=$1 n=$2
  if [[ "$disk" == *"nvme"* ]] || [[ "$disk" == *"mmcblk"* ]]; then
    printf '%sp%s\n' "$disk" "$n"
  else
    printf '%s%s\n' "$disk" "$n"
  fi
}

disk_model() {
  local disk=$1 base model=""
  base=$(basename "$disk")
  model=$(lsblk -dn -o MODEL "$disk" 2>/dev/null | head -n1 || true)
  if [[ -z "$model" && -r "/sys/block/${base}/device/model" ]]; then
    model=$(tr -s ' ' </sys/block/"$base"/device/model)
    model=${model%% }
  fi
  printf '%s\n' "$model"
}

assert_data_disk() {
  local disk=$1
  local base model by_id resolved
  base=$(basename "$disk")
  [[ "$base" != *"$nvme_guard"* ]] || die "refusing to touch UOS disk ${disk}"

  by_id="/dev/disk/by-id/${sda_by_id}"
  if [[ -b "$by_id" ]]; then
    resolved=$(readlink -f "$by_id")
    [[ "$resolved" == "$disk" ]] ||
      die "disk ${disk} is not ${sda_by_id} (that id is ${resolved})"
    return 0
  fi

  model=$(disk_model "$disk")
  [[ "$model" == *"$expected_model_token"* ]] ||
    die "disk ${disk} model is '${model:-unknown}', expected it to contain ${expected_model_token}"
}

fstype_of() {
  lsblk -no FSTYPE "$1" 2>/dev/null | head -n1 | tr -d '[:space:]'
}

label_of() {
  lsblk -no LABEL "$1" 2>/dev/null | head -n1 | tr -d '[:space:]'
}

mounted_at() {
  findmnt -n -o TARGET -S "$1" 2>/dev/null | tr '\n' ',' | sed 's/,$//' || true
}

is_mounted() {
  findmnt -n --mountpoint "$1" >/dev/null 2>&1
}

mnt_fsroot() {
  findmnt -n -o FSROOT "$1" 2>/dev/null || true
}

ensure_nixos_root_mount() {
  local p4=$1
  local fsroot
  as_root mkdir -p "${root_mnt}"
  if is_mounted "${root_mnt}"; then
    fsroot=$(mnt_fsroot "${root_mnt}")
    if [[ "$fsroot" == "/@nixos" || "$fsroot" == "@nixos" ]]; then
      ok "${root_mnt} is already @nixos (future NixOS /)"
      return 0
    fi
    warn "${root_mnt} is ${fsroot:-unknown}; remounting as @nixos"
    as_root umount -R "${root_mnt}"
  fi
  as_root mount -o subvol=@nixos,compress=zstd,noatime "$p4" "${root_mnt}"
  fsroot=$(mnt_fsroot "${root_mnt}")
  [[ "$fsroot" == "/@nixos" || "$fsroot" == "@nixos" ]] ||
    die "${root_mnt} mounted ${fsroot:-nothing}, want /@nixos"
  ok "mounted @nixos -> ${root_mnt}  (this is NixOS / after install)"
}

show_status() {
  local disk p1 p2 p3 p4
  disk=$(resolve_sda)
  p1=$(part "$disk" 1)
  p2=$(part "$disk" 2)
  p3=$(part "$disk" 3)
  p4=$(part "$disk" 4)

  heading "NixOS beside UOS"
  item "flake     ${flake_uri}"
  item "root      ${root_mnt}"
  item "disk      ${disk}"
  item "model     $(disk_model "$disk")"
  item "UOS stays on /dev/${nvme_guard} (never touched)"
  printf '%s│%s\n' "$c_cyan" "$c_reset"
  item "$(printf '%-10s %-8s %-12s %s' PART FSTYPE LABEL MOUNT)"
  for spec in "1 efi/boot-efi" "2 boot" "3 watermelon/share" "4 banana/root"; do
    local n role dev fs lab mnt
    n=${spec%% *}
    role=${spec#* }
    dev=$(part "$disk" "$n")
    if [[ -b "$dev" ]]; then
      fs=$(fstype_of "$dev")
      lab=$(label_of "$dev")
      mnt=$(mounted_at "$dev")
      item "$(printf '%-10s %-8s %-12s %s  (%s)' "$(basename "$dev")" "${fs:--}" "${lab:--}" "${mnt:--}" "$role")"
    else
      bad "$(basename "$dev") missing"
    fi
  done
  printf '%s│%s\n' "$c_cyan" "$c_reset"
  if [[ ! -d "${root_mnt}" ]]; then
    bad "${root_mnt} directory is missing (menu 3 creates it with sudo)"
  elif is_mounted "${root_mnt}"; then
    local fsroot
    fsroot=$(mnt_fsroot "${root_mnt}")
    if [[ "$fsroot" == "/@nixos" || "$fsroot" == "@nixos" ]]; then
      ok "NixOS /  is ${root_mnt}  (btrfs ${p4} subvol=@nixos)"
    else
      bad "${root_mnt} is ${fsroot:-unknown}; want subvol=@nixos (menu 3 remounts)"
    fi
    findmnt -R -n -o TARGET,SOURCE,FSTYPE "${root_mnt}" 2>/dev/null |
      while IFS= read -r line; do
        note "$line"
      done
    is_mounted "${root_mnt}/nix" && ok "NixOS /nix  ${root_mnt}/nix  (@nix)" ||
      warn "/nix not mounted"
    is_mounted "${root_mnt}/home" && ok "NixOS /home ${root_mnt}/home (@home)" ||
      warn "/home not mounted"
    is_mounted "${root_mnt}/swap" && ok "NixOS /swap ${root_mnt}/swap (@swap)" ||
      warn "/swap not mounted"
    if [[ -f "${root_mnt}/swap/swapfile" ]]; then
      ok "swapfile ${root_mnt}/swap/swapfile"
    else
      warn "16G swapfile missing (menu swap)"
    fi
    is_mounted "${root_mnt}/boot" && ok "NixOS /boot ${root_mnt}/boot" ||
      warn "/boot not mounted (menu 3 after format)"
    is_mounted "${root_mnt}/boot/efi" && ok "NixOS /boot/efi ${root_mnt}/boot/efi" ||
      warn "/boot/efi not mounted (menu 3 after format)"
  else
    warn "${root_mnt} exists but @nixos is not mounted there"
    note "menu 3 mounts @nixos as the NixOS root (UOS / stays on nvme)"
  fi
  command -v nixos-install >/dev/null && ok "nixos-install on PATH" ||
    warn "nixos-install missing (nix profile install nixpkgs#nixos-install-tools)"
}

create_subvolumes() {
  local disk p4 tmp
  disk=$(resolve_sda)
  assert_data_disk "$disk"
  p4=$(part "$disk" 4)
  [[ "$(fstype_of "$p4")" == btrfs ]] || die "${p4} is not btrfs (do not mkfs)"

  heading "Create @nixos @nix @home @swap on banana"
  item "mount ${p4} at a temp dir with subvolid=5"
  tmp=$(mktemp -d /tmp/banana-XXXX)
  as_root mount -o subvolid=5,noatime "$p4" "$tmp"
  local vol
  for vol in @nixos @nix @home @swap; do
    if as_root btrfs subvolume show "${tmp}/${vol}" >/dev/null 2>&1; then
      ok "${vol} already exists"
    else
      as_root btrfs subvolume create "${tmp}/${vol}"
      ok "created ${vol}"
    fi
  done
  as_root btrfs subvolume list "$tmp" || true
  if as_root btrfs subvolume set-default "${tmp}/@nixos"; then
    ok "default subvolume is @nixos (NixOS /)"
  else
    local nixos_id
    nixos_id=$(as_root btrfs subvolume list "$tmp" | awk '$NF=="@nixos"{print $2; exit}')
    [[ -n "$nixos_id" ]] || die "could not find @nixos id"
    as_root btrfs subvolume set-default "$nixos_id" "$tmp"
    ok "default subvolume id ${nixos_id} (@nixos)"
  fi
  as_root umount "$tmp"
  rmdir "$tmp"
  ok "unmounted; banana filesystem was not formatted"
}

mount_tree() {
  local disk p1 p2 p3 p4
  disk=$(resolve_sda)
  assert_data_disk "$disk"
  p1=$(part "$disk" 1)
  p2=$(part "$disk" 2)
  p3=$(part "$disk" 3)
  p4=$(part "$disk" 4)

  heading "Mount install tree under ${root_mnt}"
  item "@nixos is the NixOS root filesystem (mounted at ${root_mnt} while UOS is running)"
  [[ "$(fstype_of "$p4")" == btrfs ]] || die "${p4} is not btrfs"
  [[ "$(fstype_of "$p3")" == ext4 ]] || die "${p3} is not ext4 watermelon"

  ensure_nixos_root_mount "$p4"
  as_root mkdir -p "${root_mnt}"/{nix,home,boot,boot/efi,share,swap}

  is_mounted "${root_mnt}/nix" || as_root mount -o subvol=@nix,compress=zstd,noatime "$p4" "${root_mnt}/nix"
  ok "@nix -> ${root_mnt}/nix"

  is_mounted "${root_mnt}/home" || as_root mount -o subvol=@home,compress=zstd,noatime "$p4" "${root_mnt}/home"
  ok "@home -> ${root_mnt}/home"

  is_mounted "${root_mnt}/swap" && ok "@swap already at ${root_mnt}/swap" || {
    if as_root mount -o subvol=@swap,compress=no,noatime "$p4" "${root_mnt}/swap"; then
      ok "@swap -> ${root_mnt}/swap"
    else
      warn "@swap missing (menu 7 / swap creates it)"
    fi
  }

  is_mounted "${root_mnt}/share" || as_root mount "$p3" "${root_mnt}/share"
  ok "watermelon -> ${root_mnt}/share"

  mount_boot_efi "$p1" "$p2"
  findmnt -R "${root_mnt}" || true
}

mount_boot_efi() {
  local p1=$1 p2=$2
  local lab2 fs2 fs1

  as_root mkdir -p "${root_mnt}/boot/efi"
  as_root udevadm settle >/dev/null 2>&1 || true
  lab2=$(label_of "$p2")
  fs2=$(fstype_of "$p2")
  fs1=$(fstype_of "$p1")

  if [[ "$lab2" == apple ]]; then
    warn "${p2} still labeled apple; format-boot before using it as /boot"
  elif [[ "$fs2" != ext4 ]]; then
    warn "${p2} fstype=${fs2:-empty}; expected ext4 labeled boot"
  else
    if is_mounted "${root_mnt}/boot"; then
      ok "boot already mounted at ${root_mnt}/boot"
    else
      as_root mount -t ext4 "$p2" "${root_mnt}/boot"
      is_mounted "${root_mnt}/boot" || die "failed to mount ${p2} on ${root_mnt}/boot"
      ok "boot -> ${root_mnt}/boot (${p2})"
    fi
  fi

  as_root mkdir -p "${root_mnt}/boot/efi"
  if [[ "$fs1" != vfat ]]; then
    warn "${p1} fstype=${fs1:-empty}; expected vfat EFI"
  else
    if is_mounted "${root_mnt}/boot/efi"; then
      ok "efi already mounted at ${root_mnt}/boot/efi"
    else
      as_root mount -t vfat -o umask=0077 "$p1" "${root_mnt}/boot/efi"
      is_mounted "${root_mnt}/boot/efi" || die "failed to mount ${p1} on ${root_mnt}/boot/efi"
      ok "efi -> ${root_mnt}/boot/efi (${p1})"
    fi
  fi
}

unmount_device() {
  local dev=$1 target
  while target=$(findmnt -n -o TARGET -S "$dev" | head -n1); do
    [[ -n "$target" ]] || break
    item "unmount ${dev} from ${target}"
    as_root umount "$target" || as_root umount -l "$target" || true
    if command -v udisksctl >/dev/null 2>&1; then
      udisksctl unmount -b "$dev" >/dev/null 2>&1 || true
    fi
    if findmnt -n -S "$dev" >/dev/null 2>&1; then
      die "still mounted: ${dev} -> $(findmnt -n -o TARGET -S "$dev" | tr '\n' ' ')"
    fi
  done
}

format_efi_boot() {
  local disk p1 p2 mkfat mkext
  disk=$(resolve_sda)
  assert_data_disk "$disk"
  p1=$(part "$disk" 1)
  p2=$(part "$disk" 2)
  mkfat=$(command -v mkfs.vfat || command -v mkfs.fat || true)
  mkext=$(command -v mkfs.ext4 || true)
  [[ -x "$mkfat" ]] || mkfat=/sbin/mkfs.vfat
  [[ -x "$mkext" ]] || mkext=/sbin/mkfs.ext4
  [[ -x "$mkfat" ]] || die "mkfs.vfat not found"
  [[ -x "$mkext" ]] || die "mkfs.ext4 not found"

  heading "Format EFI + /boot only"
  bad "this destroys current sda1 (systemd/EFI) and sda2 (apple)"
  item "will NOT touch ${disk}3 watermelon or ${disk}4 banana"
  item "will NOT touch /dev/${nvme_guard}"
  item "unmount ${p1} (/mnt/boot/efi) and ${p2} (/media/Designers/apple) first"
  note "copy anything you need off apple before continuing"

  confirm "reformat EFI ${p1} and boot ${p2}?" "FORMAT EFI BOOT" || {
    warn "aborted (type exactly: FORMAT EFI BOOT)"
    return 0
  }

  unmount_device "$p1"
  unmount_device "$p2"

  as_root "$mkfat" -F 32 -n EFI "$p1"
  ok "formatted ${p1} vfat EFI"
  as_root "$mkext" -F -L boot "$p2"
  ok "formatted ${p2} ext4 boot"

  heading "Mount EFI + /boot"
  as_root mkdir -p "${root_mnt}"/{boot,boot/efi}
  if ! is_mounted "${root_mnt}"; then
    warn "${root_mnt} is not @nixos yet; mounting full tree"
    mount_tree
    return 0
  fi
  mount_boot_efi "$p1" "$p2"
  findmnt -R "${root_mnt}" || true
}

create_swapfile() {
  local disk p4 swap_path kernel
  disk=$(resolve_sda)
  assert_data_disk "$disk"
  p4=$(part "$disk" 4)
  swap_path="${root_mnt}/swap/swapfile"

  heading "16G btrfs swapfile on banana @swap"
  item "nocow empty file, then fallocate; never mkfs ${p4}"
  create_subvolumes
  mount_tree
  is_mounted "${root_mnt}/swap" || die "${root_mnt}/swap is not mounted"

  if [[ -f "$swap_path" ]]; then
    ok "swapfile already exists"
  else
    as_root truncate -s 0 "$swap_path"
    as_root chattr +C "$swap_path"
    as_root fallocate -l 16G "$swap_path" ||
      as_root dd if=/dev/zero of="$swap_path" bs=1M count=16384 status=progress
    as_root chmod 600 "$swap_path"
    as_root mkswap "$swap_path"
    ok "created 16G ${swap_path}"
  fi

  kernel=$(uname -r)
  if as_root swapon "$swap_path"; then
    ok "swap is active"
  else
    warn "swapon failed (UOS ${kernel} cannot use btrfs swapfiles; NixOS 6.18 can)"
  fi
  as_root swapon --show || true
}

unmount_tree() {
  heading "Unmount ${root_mnt}"
  if ! is_mounted "${root_mnt}"; then
    warn "${root_mnt} is not mounted"
    return 0
  fi
  as_root umount -R "${root_mnt}"
  ok "unmounted ${root_mnt}"
}

install_bootloader() {
  local enter path
  enter="${script_dir}/nixos-enter-uos.sh"
  path=$(root_path)
  [[ -e "${root_mnt}/etc/NIXOS" ]] || die "${root_mnt} is not a NixOS installation"
  [[ -x "$enter" ]] || die "missing ${enter}"
  heading "GRUB via nixos-enter without --mount-proc"
  item "UOS keeps binfmt_misc under /proc; upstream nixos-enter remounts /proc and gets EBUSY"
  as_root ln -sfn /proc/mounts "${root_mnt}/etc/mtab"
  as_root env PATH="$path" LC_ALL=C LANG=C LANGUAGE=C \
    NIXOS_INSTALL_BOOTLOADER=1 mountPoint="${root_mnt}" \
    "$enter" --root "${root_mnt}" -c '
      set -e
      export PATH="/nix/var/nix/profiles/system/sw/bin:/nix/var/nix/profiles/system/bin"
      hash -r
      mkdir -p /run
      ln -sfn /nix/var/nix/profiles/system /run/current-system
      mount --rbind --mkdir / "$mountPoint"
      mount --make-rslave "$mountPoint"
      /nix/var/nix/profiles/system/bin/switch-to-configuration boot
      umount -R "$mountPoint" && (rmdir "$mountPoint" 2>/dev/null || true)
    '
  ok "bootloader installed (removable EFI on sda1)"
}

seed_fhs_init() {
  local init="${root_mnt}/nix/var/nix/profiles/system/init"
  [[ -e "$init" ]] || die "missing ${init}; run install first"
  heading "FHS init for systemd-nspawn --boot"
  item "nspawn looks for /sbin/init; NixOS keeps systemd in the profile"
  as_root mkdir -p "${root_mnt}/sbin" "${root_mnt}/usr/lib/systemd"
  as_root ln -sfn /nix/var/nix/profiles/system/init "${root_mnt}/sbin/init"
  as_root ln -sfn /nix/var/nix/profiles/system/init "${root_mnt}/usr/lib/systemd/systemd"
  ok "/sbin/init -> /nix/var/nix/profiles/system/init"
}

run_nspawn() {
  is_mounted "${root_mnt}" || die "mount the tree first"
  [[ -e "${root_mnt}/etc/NIXOS" ]] || die "${root_mnt} is not a NixOS installation"
  heading "systemd-nspawn shell in ${root_mnt}"
  item "NixOS systemd 261 cannot be PID 1 on UOS kernel 4.19"
  item "EUNATCH (Protocol driver not attached) on /proc /sys /dev — same as udev"
  item "this is a chroot-like shell, not a NixOS boot; real test is sda EFI"
  item "exit or Ctrl-] three times to leave"
  local binds=(
    --bind="${root_mnt}/nix:/nix"
    --bind="${root_mnt}/boot:/boot"
    --bind="${root_mnt}/home:/home"
  )
  is_mounted "${root_mnt}/share" && binds+=(--bind="${root_mnt}/share:/share")
  is_mounted "${root_mnt}/swap" && binds+=(--bind="${root_mnt}/swap:/swap")
  as_root env PATH="/nix/var/nix/profiles/system/sw/bin:/nix/var/nix/profiles/system/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
    systemd-nspawn \
    --directory="${root_mnt}" \
    --machine=nixos-sda \
    --private-network \
    "${binds[@]}" \
    /nix/var/nix/profiles/system/sw/bin/bash --login
}

run_install() {
  heading "nixos-install ${flake_uri}"
  is_mounted "${root_mnt}" || die "mount the tree first"
  is_mounted "${root_mnt}/nix" || die "${root_mnt}/nix is not mounted"
  is_mounted "${root_mnt}/boot" || die "${root_mnt}/boot is not mounted"
  is_mounted "${root_mnt}/boot/efi" || die "${root_mnt}/boot/efi is not mounted"
  local install_bin nix_cmd path source_args=()
  install_bin=$(nixos_install_bin)
  nix_cmd=$(nix_bin)
  path=$(root_path)
  [[ -x "$install_bin" ]] ||
    die "nixos-install not found; as Designers run: nix profile install nixpkgs#nixos-install-tools"
  [[ -x "$nix_cmd" ]] ||
    die "nix not found; expected /nix/var/nix/profiles/default/bin/nix"
  if [[ -e /tmp/nixos-sda/init ]]; then
    source_args=(--system "$(readlink -f /tmp/nixos-sda)")
    item "system        $(readlink -f /tmp/nixos-sda)"
  else
    source_args=(--flake "$flake_uri")
    item "flake         ${flake_uri}"
  fi
  item "nixos-install  ${install_bin}"
  item "nix            ${nix_cmd}"
  item "PATH           ${path}"
  item "this copies the closure and bootloader; it does not repartition"
  item "fstab uses filesystem UUIDs (hardware-sda.nix), not Disko PARTLABELs"
  confirm "run nixos-install?" "INSTALL" || {
    warn "aborted"
    return 0
  }
  as_root env PATH="$path" /bin/bash -c '
    set -euo pipefail
    hash -r
    if ! command -v nix >/dev/null; then
      echo "nix not on PATH=$PATH" >&2
      exit 127
    fi
    if ! command -v nix-build >/dev/null; then
      echo "nix-build not on PATH=$PATH" >&2
      exit 127
    fi
    exec "$0" "$@"
  ' "$install_bin" --root "${root_mnt}" \
    "${source_args[@]}" \
    --no-channel-copy --no-bootloader --no-root-passwd \
    --option sandbox false --option filter-syscalls false
  install_bootloader
}

print_help() {
  heading "Usage"
  cat <<EOF
${c_dim}│${c_reset}  ${program_name}              interactive menu
${c_dim}│${c_reset}  ${program_name} status
${c_dim}│${c_reset}  ${program_name} subvolumes
${c_dim}│${c_reset}  ${program_name} mount
${c_dim}│${c_reset}  ${program_name} swap         (16G @swap/swapfile)
${c_dim}│${c_reset}  ${program_name} format-boot   (sda1 + sda2 only)
${c_dim}│${c_reset}  ${program_name} install
${c_dim}│${c_reset}  ${program_name} bootloader   (GRUB only; skips unshare --mount-proc)
${c_dim}│${c_reset}  ${program_name} nspawn       (shell in /mnt; --boot cannot work on 4.19)
${c_dim}│${c_reset}  ${program_name} unmount

${c_yellow}Never:${c_reset} mkfs sda3 / sda4, disko destroy/format, or touch nvme0n1.
EOF
}

menu() {
  local choice
  while true; do
    show_status
    heading "Menu"
    item "1) Refresh status"
    item "2) Create btrfs subvolumes @nixos @nix @home @swap  (no mkfs)"
    item "3) Mount install tree under ${root_mnt}"
    item "4) Format EFI + /boot  ${c_red}(sda1 and sda2 only)${c_reset}"
    item "5) Run nixos-install"
    item "6) Unmount ${root_mnt}"
    item "7) Create and enable 16G swapfile on @swap"
    item "8) Install GRUB only (no --mount-proc)"
    item "9) systemd-nspawn shell (not --boot; 4.19 cannot run systemd 261)"
    item "h) Help"
    item "q) Quit"
    choice=$(prompt_choice "Choose" 1)
    case "$choice" in
      1 | s | S | "") show_status ;;
      2) create_subvolumes ;;
      3) mount_tree ;;
      4) format_efi_boot ;;
      5) run_install ;;
      6) unmount_tree ;;
      7) create_swapfile ;;
      8) install_bootloader ;;
      9) run_nspawn ;;
      h | H | help) print_help ;;
      q | Q | quit | exit) exit 0 ;;
      *) warn "unknown choice: ${choice}" ;;
    esac
  done
}

main() {
  need_cmd lsblk
  need_cmd findmnt
  local action=${1:-menu}
  case "$action" in
    menu) menu ;;
    status) show_status ;;
    subvolumes) create_subvolumes ;;
    mount) mount_tree ;;
    swap) create_swapfile ;;
    format-boot) format_efi_boot ;;
    install) run_install ;;
    bootloader) install_bootloader ;;
    nspawn) run_nspawn ;;
    unmount) unmount_tree ;;
    -h | --help | help) print_help ;;
    *) die "unknown action: ${action}" ;;
  esac
}

main "$@"
