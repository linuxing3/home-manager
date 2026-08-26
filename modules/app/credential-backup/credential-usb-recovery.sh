#!/usr/bin/env bash

set -euo pipefail
umask 077

readonly program_name="credential-usb-recovery"
readonly archive_pattern="credential-backup-v1-*.tar"

credential_vault_bin="${CREDENTIAL_USB_VAULT_BIN:-credential-vault}"
udisksctl_bin="${CREDENTIAL_USB_UDISKSCTL_BIN:-udisksctl}"
lsblk_bin="${CREDENTIAL_USB_LSBLK_BIN:-lsblk}"
findmnt_bin="${CREDENTIAL_USB_FINDMNT_BIN:-findmnt}"

encrypted_device=""
clear_device=""
mount_point=""
unlocked_here=0
mounted_here=0

usage() {
  cat <<'EOF'
Usage:
  credential-usb-recovery list [--device /dev/DEVICE]
  credential-usb-recovery restore [latest|BACKUP_NAME] [--device /dev/DEVICE] [--yes]

The helper accepts one removable LUKS device, unlocks it through udisksctl's
local passphrase prompt, and searches it for credential-backup-v1-*.tar files.
Restore validates the archive, creates a pre-restore snapshot on the encrypted
USB, asks for confirmation unless --yes is supplied, and hardens restored file
permissions. Devices unlocked or mounted by this command are closed on exit.

Environment:
  CREDENTIAL_USB_VAULT_BIN       credential-vault executable override
  CREDENTIAL_USB_UDISKSCTL_BIN  udisksctl executable override
  CREDENTIAL_USB_LSBLK_BIN      lsblk executable override
  CREDENTIAL_USB_FINDMNT_BIN    findmnt executable override
EOF
}

die() {
  printf '%s: %s\n' "$program_name" "$*" >&2
  exit 1
}

cleanup() {
  local exit_status=$?
  trap - EXIT HUP INT TERM

  if [[ "$mounted_here" == 1 && -n "$clear_device" ]]; then
    "$udisksctl_bin" unmount -b "$clear_device" >/dev/null 2>&1 || true
  fi
  if [[ "$unlocked_here" == 1 && -n "$encrypted_device" ]]; then
    "$udisksctl_bin" lock -b "$encrypted_device" >/dev/null 2>&1 || true
  fi
  return "$exit_status"
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

require_executable() {
  local executable=$1
  if [[ "$executable" == */* ]]; then
    [[ -x "$executable" ]] || die "required executable is missing: $executable"
  else
    command -v "$executable" >/dev/null 2>&1 ||
      die "required executable is missing from PATH: $executable"
  fi
}

device_property() {
  local device=$1 column=$2
  "$lsblk_bin" -nrpo NAME,"$column" "$device" 2>/dev/null |
    awk -v device="$device" '$1 == device { print $2; exit }'
}

validate_encrypted_device() {
  local device=$1 device_type filesystem removable parent parent_removable
  [[ "$device" == /dev/* && -b "$device" ]] ||
    die "not a block device: $device"
  device_type=$(device_property "$device" TYPE)
  filesystem=$(device_property "$device" FSTYPE)
  removable=$(device_property "$device" RM)
  parent=$(device_property "$device" PKNAME)
  parent=${parent##*/}
  parent_removable=""
  [[ -n "$parent" ]] &&
    parent_removable=$(device_property "/dev/$parent" RM)
  [[ "$device_type" == part && "$filesystem" == crypto_LUKS &&
    ("$removable" == 1 || "$parent_removable" == 1) ]] ||
    die "device must be a removable LUKS partition: $device"
}

discover_encrypted_device() {
  local requested=${1:-} device
  local -a candidates=()

  if [[ -n "$requested" ]]; then
    validate_encrypted_device "$requested"
    printf '%s' "$requested"
    return
  fi

  while read -r device; do
    [[ -n "$device" ]] && candidates+=("$device")
  done < <(
    "$lsblk_bin" -nrpo NAME,TYPE,FSTYPE,RM |
      awk '$2 == "part" && $3 == "crypto_LUKS" && $4 == "1" { print $1 }'
  )
  case ${#candidates[@]} in
    0) die "no removable LUKS credential USB was found" ;;
    1) printf '%s' "${candidates[0]}" ;;
    *) die "multiple removable LUKS devices found; select one with --device" ;;
  esac
}

find_clear_device() {
  local parent_name child parent
  parent_name=${encrypted_device##*/}
  while read -r child parent; do
    [[ "$parent" == "$parent_name" ]] || continue
    printf '%s' "$child"
    return
  done < <("$lsblk_bin" -nrpo NAME,PKNAME "$encrypted_device" 2>/dev/null)
}

unlock_device() {
  local unlock_output
  clear_device=$(find_clear_device || true)
  if [[ -n "$clear_device" && -b "$clear_device" ]]; then
    return
  fi

  [[ -t 0 && -t 2 ]] || die "unlock requires an interactive terminal"
  unlock_output=$(
    "$udisksctl_bin" unlock -b "$encrypted_device"
  ) || die "unable to unlock $encrypted_device"
  clear_device=$(printf '%s\n' "$unlock_output" |
    sed -nE 's|.* as (/dev/[^.[:space:]]+).*|\1|p' | tail -n 1)
  unlock_output=""
  if [[ -z "$clear_device" || ! -b "$clear_device" ]]; then
    clear_device=$(find_clear_device || true)
  fi
  [[ -n "$clear_device" && -b "$clear_device" ]] ||
    die "LUKS unlock succeeded but its cleartext block device was not found"
  unlocked_here=1
}

mount_clear_device() {
  local mount_output
  mount_point=$("$findmnt_bin" -rn -S "$clear_device" -o TARGET | head -n 1)
  if [[ -n "$mount_point" ]]; then
    return
  fi

  mount_output=$(
    "$udisksctl_bin" mount -b "$clear_device"
  ) || die "unable to mount unlocked credential USB"
  mount_point=$("$findmnt_bin" -rn -S "$clear_device" -o TARGET | head -n 1)
  if [[ -z "$mount_point" ]]; then
    mount_point=$(printf '%s\n' "$mount_output" |
      sed -nE 's|.* at (/.+)\.?$|\1|p' | tail -n 1)
    mount_point=${mount_point%.}
  fi
  mount_output=""
  [[ -n "$mount_point" && -d "$mount_point" && ! -L "$mount_point" ]] ||
    die "credential USB mounted but its mount point was not found"
  mounted_here=1
}

list_archives() {
  local archive relative
  while IFS= read -r -d '' archive; do
    relative=${archive#"$mount_point"/}
    printf '%s\n' "$relative"
  done < <(
    find "$mount_point" -xdev -maxdepth 5 -type f -name "$archive_pattern" -print0
  ) | sort
}

select_archive() {
  local requested=$1 candidate relative
  local -a matches=()

  while IFS= read -r -d '' candidate; do
    [[ -f "$candidate" && ! -L "$candidate" ]] || continue
    relative=${candidate#"$mount_point"/}
    if [[ "$requested" == latest || "$relative" == "$requested" ||
      "${candidate##*/}" == "$requested" ]]; then
      matches+=("$candidate")
    fi
  done < <(
    find "$mount_point" -xdev -maxdepth 5 -type f -name "$archive_pattern" -print0
  )

  ((${#matches[@]} > 0)) || die "no matching regular v1 credential backup was found"
  if [[ "$requested" == latest ]]; then
    printf '%s\n' "${matches[@]}" | sort | tail -n 1
    return
  fi
  ((${#matches[@]} == 1)) ||
    die "backup name is ambiguous; use the relative path shown by list"
  printf '%s' "${matches[0]}"
}

main() {
  local command=${1:-} requested=latest requested_device="" assume_yes=no
  local argument archive_file snapshot_dir

  case "$command" in
    -h | --help | help | "") usage; return ;;
    list | restore) shift ;;
    *) usage >&2; exit 2 ;;
  esac

  while (($#)); do
    argument=$1
    shift
    case "$argument" in
      --device)
        (($#)) || die "--device requires a block device"
        requested_device=$1
        shift
        ;;
      --yes) assume_yes=yes ;;
      -*) die "unknown option: $argument" ;;
      *)
        [[ "$command" == restore && "$requested" == latest ]] ||
          die "unexpected argument: $argument"
        requested=$argument
        ;;
    esac
  done
  [[ "$command" == restore || "$assume_yes" == no ]] ||
    die "--yes is valid only with restore"

  require_executable "$credential_vault_bin"
  require_executable "$udisksctl_bin"
  require_executable "$lsblk_bin"
  require_executable "$findmnt_bin"
  encrypted_device=$(discover_encrypted_device "$requested_device")
  unlock_device
  mount_clear_device

  case "$command" in
    list)
      list_archives
      ;;
    restore)
      archive_file=$(select_archive "$requested")
      snapshot_dir="$mount_point/credential-pre-restore"
      mkdir -p -- "$snapshot_dir"
      chmod 700 "$snapshot_dir" 2>/dev/null || true
      local -a restore_args=(
        restore-local
        "$archive_file"
        --pre-restore-dir
        "$snapshot_dir"
      )
      [[ "$assume_yes" == yes ]] && restore_args+=(--yes)
      "$credential_vault_bin" "${restore_args[@]}"
      ;;
  esac
}

main "$@"
