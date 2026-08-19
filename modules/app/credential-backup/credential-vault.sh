#!/usr/bin/env bash

set -euo pipefail
umask 077

readonly program_name="credential-vault"
readonly archive_version="v1"
readonly default_bw_item="kurio.infini-cloud.net"
readonly default_remote_path="credential-backups"
readonly default_webdav_url="https://kurio.infini-cloud.net"

bw_bin="${CREDENTIAL_VAULT_BW_BIN:-$HOME/.nix-profile/bin/bw}"
rclone_bin="${CREDENTIAL_VAULT_RCLONE_BIN:-rclone}"
bw_item="${CREDENTIAL_VAULT_BW_ITEM:-$default_bw_item}"
bw_item_explicit=0
[[ -v CREDENTIAL_VAULT_BW_ITEM ]] && bw_item_explicit=1

work_dir=""
lock_file=""
local_snapshot_partial=""
unlocked_here=0
item_json=""
webdav_url=""
webdav_user=""
webdav_password=""
webdav_vendor=""
remote_path=""
crypt_password=""
crypt_password2=""

usage() {
  cat <<'EOF'
Usage:
  credential-vault
  credential-vault backup
  credential-vault list
  credential-vault restore [latest|BACKUP_NAME] [--yes]
  credential-vault restore-local ARCHIVE [--pre-restore-dir DIR] [--yes]

Environment:
  CREDENTIAL_VAULT_BW_ITEM       Bitwarden item name or ID
                                 (default: kurio.infini-cloud.net)
  CREDENTIAL_VAULT_AUTH_SOURCE   bitwarden or manual
  CREDENTIAL_VAULT_WEBDAV_URL    Non-interactive WebDAV URL override
  CREDENTIAL_VAULT_ALLOW_HTTP    Set to 1 only for a local test WebDAV server

Interactive defaults:
  WebDAV URL                     https://kurio.infini-cloud.net
  Authentication                Bitwarden, with manual entry available

The Bitwarden login item must contain:
  login.username                 InfinityCloud WebDAV username
  login.password                 InfinityCloud WebDAV password

Optional custom fields:
  crypt_password                 Stable rclone crypt password (recommended)
  webdav_url                     Saved custom endpoint for non-interactive use
  webdav_vendor                  rclone WebDAV vendor (default: other)
  remote_path                    WebDAV directory (default: credential-backups)
  crypt_password2                rclone crypt filename-encryption salt
EOF
}

print_heading() {
  local title=$1
  if [[ -t 2 ]]; then
    printf '\033[1;36m╭─ %s\033[0m\n' "$title" >&2
  else
    printf '== %s ==\n' "$title" >&2
  fi
}

prompt_choice() {
  local prompt=$1 default_choice=$2 target=$3 answer
  printf '╰─ %s [%s]: ' "$prompt" "$default_choice" >&2
  IFS= read -r answer
  answer=${answer:-$default_choice}
  printf -v "$target" '%s' "$answer"
}

read_masked_password() {
  local prompt=$1 target=$2 character value=""
  [[ -t 0 ]] || die "password input requires a terminal"

  printf '%s' "$prompt" >&2
  while IFS= read -r -s -n 1 character; do
    if [[ -z "$character" ]]; then
      break
    fi
    case "$character" in
      $'\177' | $'\b')
        if [[ -n "$value" ]]; then
          value=${value%?}
          printf '\b \b' >&2
        fi
        ;;
      *)
        value+=$character
        printf '*' >&2
        ;;
    esac
  done
  printf '\n' >&2
  printf -v "$target" '%s' "$value"
  value=""
}

choose_action() {
  local target=$1 choice
  [[ -t 0 ]] || die "no action supplied; run with --help for usage"

  print_heading "Credential Vault"
  printf '│  1) Back up credentials\n' >&2
  printf '│  2) List encrypted backups\n' >&2
  printf '│  3) Restore the latest backup\n' >&2
  printf '│  4) Show help\n' >&2
  printf '│  q) Quit\n' >&2
  prompt_choice "Choose an action" 1 choice
  case "$choice" in
    1 | b | B) printf -v "$target" '%s' backup ;;
    2 | l | L) printf -v "$target" '%s' list ;;
    3 | r | R) printf -v "$target" '%s' restore ;;
    4 | h | H) printf -v "$target" '%s' help ;;
    q | Q) exit 0 ;;
    *) die "unknown action: $choice" ;;
  esac
}

die() {
  printf '%s: %s\n' "$program_name" "$*" >&2
  exit 1
}

cleanup() {
  local exit_status=$?

  trap - EXIT HUP INT TERM

  item_json=""
  webdav_url=""
  webdav_user=""
  webdav_password=""
  webdav_vendor=""
  remote_path=""
  crypt_password=""
  crypt_password2=""
  unset BW_SESSION
  unset RCLONE_CONFIG_INFINITY_TYPE RCLONE_CONFIG_INFINITY_URL
  unset RCLONE_CONFIG_INFINITY_VENDOR RCLONE_CONFIG_INFINITY_USER
  unset RCLONE_CONFIG_INFINITY_PASS RCLONE_CONFIG_CREDENTIALVAULT_TYPE
  unset RCLONE_CONFIG_CREDENTIALVAULT_REMOTE
  unset RCLONE_CONFIG_CREDENTIALVAULT_FILENAME_ENCRYPTION
  unset RCLONE_CONFIG_CREDENTIALVAULT_DIRECTORY_NAME_ENCRYPTION
  unset RCLONE_CONFIG_CREDENTIALVAULT_PASSWORD
  unset RCLONE_CONFIG_CREDENTIALVAULT_PASSWORD2

  if [[ "$unlocked_here" == 1 && -x "$bw_bin" ]]; then
    "$bw_bin" lock >/dev/null 2>&1 || true
  fi
  if [[ -n "$work_dir" && -d "$work_dir" ]]; then
    rm -rf -- "$work_dir"
  fi
  if [[ -n "$local_snapshot_partial" && -f "$local_snapshot_partial" &&
    ! -L "$local_snapshot_partial" ]]; then
    rm -f -- "$local_snapshot_partial"
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

rclone_clean() (
  local assignment variable
  while IFS= read -r -d '' assignment; do
    variable=${assignment%%=*}
    case "$variable" in
      RCLONE_CONFIG_INFINITY_TYPE | \
        RCLONE_CONFIG_INFINITY_URL | \
        RCLONE_CONFIG_INFINITY_VENDOR | \
        RCLONE_CONFIG_INFINITY_USER | \
        RCLONE_CONFIG_INFINITY_PASS | \
        RCLONE_CONFIG_CREDENTIALVAULT_TYPE | \
        RCLONE_CONFIG_CREDENTIALVAULT_REMOTE | \
        RCLONE_CONFIG_CREDENTIALVAULT_FILENAME_ENCRYPTION | \
        RCLONE_CONFIG_CREDENTIALVAULT_DIRECTORY_NAME_ENCRYPTION | \
        RCLONE_CONFIG_CREDENTIALVAULT_PASSWORD | \
        RCLONE_CONFIG_CREDENTIALVAULT_PASSWORD2)
        ;;
      RCLONE_*) unset "$variable" ;;
      *) ;;
    esac
    assignment=""
  done < <(env -0)
  "$rclone_bin" "$@"
)

prepare_runtime() {
  local runtime_base runtime_parent runtime_owner
  if [[ -n "${XDG_RUNTIME_DIR:-}" ]]; then
    runtime_base=$XDG_RUNTIME_DIR
  else
    runtime_parent=${TMPDIR:-/tmp}
    runtime_base="$runtime_parent/credential-vault-$UID"
    if [[ -e "$runtime_base" || -L "$runtime_base" ]]; then
      [[ -d "$runtime_base" && ! -L "$runtime_base" ]] ||
        die "unsafe fallback runtime path: $runtime_base"
      runtime_owner=$(stat -c '%u' "$runtime_base")
      [[ "$runtime_owner" == "$UID" ]] ||
        die "fallback runtime directory is not owned by the current user"
    else
      mkdir -m 700 -- "$runtime_base"
    fi
    chmod 700 "$runtime_base"
  fi
  [[ -d "$runtime_base" && ! -L "$runtime_base" && -w "$runtime_base" ]] ||
    die "runtime directory is unavailable: $runtime_base"
  runtime_owner=$(stat -c '%u' "$runtime_base")
  [[ "$runtime_owner" == "$UID" ]] ||
    die "runtime directory is not owned by the current user"

  lock_file="$runtime_base/credential-vault.lock"
  exec 9>"$lock_file"
  chmod 600 "$lock_file"
  flock -n 9 || die "another credential-vault operation is running"

  work_dir=$(mktemp -d "$runtime_base/credential-vault.XXXXXX")
  chmod 700 "$work_dir"
}

custom_field() {
  local field_name=$1
  printf '%s' "$item_json" |
    jq -r --arg field_name "$field_name" '
      [
        .fields[]?
        | select((.name | ascii_downcase) == ($field_name | ascii_downcase))
        | .value
      ][0] // empty
    '
}

resolve_bitwarden_item() {
  local search_json selected_item

  if item_json=$("$bw_bin" get item "$bw_item" 2>/dev/null); then
    return
  fi
  if [[ "$bw_item_explicit" == 1 ]]; then
    die "Bitwarden item was not found or was ambiguous: $bw_item"
  fi

  search_json=$("$bw_bin" list items --search infini 2>/dev/null) ||
    die "Bitwarden item search failed"
  selected_item=$(printf '%s' "$search_json" | jq -c '
    def lower_name: (.name // "" | ascii_downcase);
    [
      .[]
      | select(.login? != null)
      | select((lower_name | contains("infini")) and (lower_name | contains("cloud")))
    ] as $cloud_items
    | [$cloud_items[] | select(lower_name | contains("webdav"))] as $webdav_items
    | if ($webdav_items | length) == 1 then
        $webdav_items[0]
      elif (($webdav_items | length) == 0 and ($cloud_items | length) == 1) then
        $cloud_items[0]
      else
        empty
      end
  ')
  search_json=""
  [[ -n "$selected_item" ]] ||
    die "no unique InfiniCLOUD/InfinityCloud login item was found; set CREDENTIAL_VAULT_BW_ITEM to its exact name or ID"
  item_json=$selected_item
  selected_item=""
}

choose_webdav_url() {
  local suggested_url=${1:-} choice entered_url

  if [[ -v CREDENTIAL_VAULT_WEBDAV_URL ]]; then
    webdav_url=$CREDENTIAL_VAULT_WEBDAV_URL
    return
  fi
  if [[ ! -t 0 ]]; then
    webdav_url=${suggested_url:-$default_webdav_url}
    return
  fi

  print_heading "WebDAV endpoint"
  printf '│  1) Use default: %s\n' "$default_webdav_url" >&2
  printf '│  2) Enter another URL\n' >&2
  prompt_choice "Choose the login URL" 1 choice
  case "$choice" in
    1 | d | D)
      webdav_url=$default_webdav_url
      ;;
    2 | c | C)
      if [[ -n "$suggested_url" ]]; then
        printf 'Custom URL [%s]: ' "$suggested_url" >&2
      else
        printf 'Custom URL: ' >&2
      fi
      IFS= read -r entered_url
      webdav_url=${entered_url:-$suggested_url}
      [[ -n "$webdav_url" ]] || die "custom WebDAV URL must not be empty"
      ;;
    *) die "unknown URL choice: $choice" ;;
  esac
}

read_encryption_password() {
  local confirmation

  printf '%s\n' "Use the same encryption password for every backup and restore." >&2
  read_masked_password "Backup encryption password: " crypt_password
  [[ -n "$crypt_password" ]] || die "backup encryption password must not be empty"
  read_masked_password "Confirm encryption password: " confirmation
  [[ "$crypt_password" == "$confirmation" ]] || die "encryption passwords do not match"
  confirmation=""
}

configure_remote() {
  [[ -n "$webdav_user" ]] || die "WebDAV username must not be empty"
  [[ -n "$webdav_password" ]] || die "WebDAV password must not be empty"
  [[ -n "$webdav_url" ]] || die "WebDAV URL must not be empty"
  [[ -n "$crypt_password" ]] || die "backup encryption password must not be empty"
  [[ "$webdav_password" != *$'\n'* ]] ||
    die "WebDAV passwords containing newlines are unsupported"
  [[ "$crypt_password" != *$'\n'* && "$crypt_password2" != *$'\n'* ]] ||
    die "rclone crypt passwords containing newlines are unsupported"

  if [[ "$webdav_url" != https://* ]]; then
    [[ "${CREDENTIAL_VAULT_ALLOW_HTTP:-0}" == 1 && "$webdav_url" == http://* ]] ||
      die "WebDAV URL must use HTTPS"
  fi

  webdav_vendor=${webdav_vendor:-other}
  remote_path=${remote_path:-$default_remote_path}
  remote_path=${remote_path#/}
  remote_path=${remote_path%/}
  [[ -n "$remote_path" ]] || die "remote_path must not be empty"
  case "$remote_path" in
    *..* | *:*) die "remote_path contains an unsafe component" ;;
  esac
  case "$webdav_vendor" in
    *[!A-Za-z0-9_-]*) die "webdav_vendor contains unsupported characters" ;;
  esac

  export RCLONE_CONFIG_INFINITY_TYPE=webdav
  export RCLONE_CONFIG_INFINITY_URL=$webdav_url
  export RCLONE_CONFIG_INFINITY_VENDOR=$webdav_vendor
  export RCLONE_CONFIG_INFINITY_USER=$webdav_user
  export RCLONE_CONFIG_INFINITY_PASS
  RCLONE_CONFIG_INFINITY_PASS=$(printf '%s\n' "$webdav_password" | rclone_clean obscure -)

  export RCLONE_CONFIG_CREDENTIALVAULT_TYPE=crypt
  export RCLONE_CONFIG_CREDENTIALVAULT_REMOTE="infinity:$remote_path"
  export RCLONE_CONFIG_CREDENTIALVAULT_FILENAME_ENCRYPTION=standard
  export RCLONE_CONFIG_CREDENTIALVAULT_DIRECTORY_NAME_ENCRYPTION=true
  export RCLONE_CONFIG_CREDENTIALVAULT_PASSWORD
  RCLONE_CONFIG_CREDENTIALVAULT_PASSWORD=$(printf '%s\n' "$crypt_password" | rclone_clean obscure -)
  unset RCLONE_CONFIG_CREDENTIALVAULT_PASSWORD2
  if [[ -n "$crypt_password2" ]]; then
    export RCLONE_CONFIG_CREDENTIALVAULT_PASSWORD2
    RCLONE_CONFIG_CREDENTIALVAULT_PASSWORD2=$(printf '%s\n' "$crypt_password2" | rclone_clean obscure -)
  fi

  item_json=""
  webdav_password=""
  crypt_password=""
  crypt_password2=""
}

load_bitwarden_credentials() {
  local status session master_password suggested_url

  require_executable "$bw_bin"
  status=$("$bw_bin" status | jq -r '.status // empty')
  case "$status" in
    unlocked)
      ;;
    locked)
      [[ -t 0 ]] ||
        die "Bitwarden is locked; run this command from a terminal to unlock it securely"
      print_heading "Unlock Bitwarden"
      read_masked_password "Master password: " master_password
      [[ -n "$master_password" ]] || die "Bitwarden master password must not be empty"
      if ! session=$(BW_MASTER_PASSWORD="$master_password" \
        "$bw_bin" unlock --passwordenv BW_MASTER_PASSWORD --raw); then
        master_password=""
        die "Bitwarden unlock failed"
      fi
      master_password=""
      [[ -n "$session" ]] || die "Bitwarden unlock returned an empty session"
      export BW_SESSION=$session
      session=""
      unlocked_here=1
      ;;
    unauthenticated)
      die "Bitwarden is not logged in; run '$bw_bin login' locally first"
      ;;
    *)
      die "unable to determine Bitwarden status"
      ;;
  esac

  "$bw_bin" sync >/dev/null
  resolve_bitwarden_item

  webdav_user=$(printf '%s' "$item_json" | jq -r '.login.username // empty')
  webdav_password=$(printf '%s' "$item_json" | jq -r '.login.password // empty')
  suggested_url=$(custom_field webdav_url)
  if [[ -z "$suggested_url" ]]; then
    suggested_url=$(printf '%s' "$item_json" | jq -r '.login.uris[0].uri // empty')
  fi
  webdav_vendor=$(custom_field webdav_vendor)
  remote_path=$(custom_field remote_path)
  crypt_password=$(custom_field crypt_password)
  crypt_password2=$(custom_field crypt_password2)

  choose_webdav_url "$suggested_url"
  if [[ -z "$crypt_password" ]]; then
    [[ -t 0 ]] ||
      die "Bitwarden item has no crypt_password; add it or run interactively"
    print_heading "Backup encryption"
    printf '│  Bitwarden has no crypt_password; enter one for this run.\n' >&2
    read_encryption_password
  fi
  configure_remote
}

load_manual_credentials() {
  print_heading "Manual WebDAV login"
  choose_webdav_url ""
  printf 'Username: ' >&2
  IFS= read -r webdav_user
  read_masked_password "Password: " webdav_password
  print_heading "Backup encryption"
  read_encryption_password
  webdav_vendor=other
  remote_path=$default_remote_path
  crypt_password2=""
  configure_remote
}

load_credentials() {
  local source=${CREDENTIAL_VAULT_AUTH_SOURCE:-} choice

  if [[ -z "$source" && -t 0 ]]; then
    print_heading "Authentication"
    printf '│  1) Use Bitwarden (default)\n' >&2
    printf '│  2) Enter credentials for this run\n' >&2
    prompt_choice "Choose a login method" 1 choice
    case "$choice" in
      1 | b | B) source=bitwarden ;;
      2 | m | M) source=manual ;;
      *) die "unknown login choice: $choice" ;;
    esac
  fi
  source=${source:-bitwarden}
  case "$source" in
    bitwarden) load_bitwarden_credentials ;;
    manual) load_manual_credentials ;;
    *) die "CREDENTIAL_VAULT_AUTH_SOURCE must be bitwarden or manual" ;;
  esac
}

rclone_vault() {
  rclone_clean --config /dev/null "$@"
}

add_path() {
  local absolute_path=$1 relative_path
  if [[ ! -e "$absolute_path" && ! -L "$absolute_path" ]]; then
    return
  fi

  case "$absolute_path" in
    "$HOME"/*) relative_path=${absolute_path#"$HOME"/} ;;
    *) die "refusing to archive a path outside HOME: $absolute_path" ;;
  esac
  case "$relative_path" in
    "" | /* | ../* | */../* | */..) die "unsafe archive path: $relative_path" ;;
  esac
  printf '%s\0' "$relative_path" >>"$work_dir/files.nul"
}

build_manifest() {
  local candidate
  : >"$work_dir/files.nul"
  chmod 600 "$work_dir/files.nul"
  shopt -s nullglob

  local -a candidates=(
    "$HOME/.ssh/id_ed25519"
    "$HOME/.ssh/id_ed25519.pub"
    "$HOME/.ssh/id_rsa"
    "$HOME/.ssh/id_rsa.pub"
    "$HOME/.ssh/config"
    "$HOME/.ssh/known_hosts"
    "$HOME/.ssh/authorized_keys"
    "$HOME/.gnupg/private-keys-v1.d"
    "$HOME/.gnupg/openpgp-revocs.d"
    "$HOME/.gnupg/pubring.kbx"
    "$HOME/.gnupg/trustdb.gpg"
    "$HOME/.gnupg/sshcontrol"
    "$HOME/.codex/auth.json"
    "$HOME/.config/cursor/auth.json"
    "$HOME/.grok/auth.json"
    "$HOME/.pi/agent/auth.json"
    "$HOME/.cli-proxy-api/"*.json
    "$HOME/.config/bash/extra/private.bash"
    "$HOME/.config/cursor-to-openai.env"
    "$HOME/.cnb/token"
    "$HOME/.config/gh/hosts.yml"
    "$HOME/.config/bitwarden/env"
    "$HOME/.config/Bitwarden CLI/data.json"
    "$HOME/.config/rclone/rclone.conf"
    "$HOME/.config/rclone/"*oauth*.json
    "$HOME/.cloudflared/cert.pem"
    "$HOME/.cloudflared/"*.json
    "$HOME/.cloudflared/"*.env
    "$HOME/.cloudflared/"*token*
    "$HOME/.config/gcloud/application_default_credentials.json"
    "$HOME/.config/gcloud/credentials.db"
    "$HOME/.config/gcloud/access_tokens.db"
    "$HOME/.local/share/atuin/key"
    "$HOME/.local/share/keyrings"
    "$HOME/.pki"
    "$HOME/.config/chromium/Local State"
    "$HOME/.config/chromium/"*/Login\ Data*
    "$HOME/.config/BraveSoftware/Brave-Browser/Local State"
    "$HOME/.config/BraveSoftware/Brave-Browser/"*/Login\ Data*
    "$HOME/.config/google-chrome/Local State"
    "$HOME/.config/google-chrome/"*/Login\ Data*
    "$HOME/.config/qaxbrowser/Local State"
    "$HOME/.config/qaxbrowser/"*/Login\ Data*
  )

  for candidate in "${candidates[@]}"; do
    add_path "$candidate"
  done
  sort -zu -o "$work_dir/files.nul" "$work_dir/files.nul"

  [[ -s "$work_dir/files.nul" ]]
}

archive_entry_allowed() {
  local entry=${1#./}
  entry=${entry%/}
  case "$entry" in
    .ssh | .ssh/* | .gnupg | .gnupg/*)
      return 0
      ;;
    .codex/auth.json | .config/cursor/auth.json)
      return 0
      ;;
    .grok/auth.json)
      return 0
      ;;
    .pi/agent/auth.json | .cli-proxy-api/*.json)
      return 0
      ;;
    .config/bash/extra/private.bash | .config/cursor-to-openai.env)
      return 0
      ;;
    .cnb/token | .config/gh/hosts.yml | .config/bitwarden/env)
      return 0
      ;;
    ".config/Bitwarden CLI/data.json" | .config/rclone/rclone.conf)
      return 0
      ;;
    .config/rclone/*oauth*.json | .cloudflared/cert.pem)
      return 0
      ;;
    .cloudflared/*.json | .cloudflared/*.env | .cloudflared/*token*)
      return 0
      ;;
    .config/gcloud/application_default_credentials.json)
      return 0
      ;;
    .config/gcloud/credentials.db | .config/gcloud/access_tokens.db)
      return 0
      ;;
    .local/share/atuin/key | .local/share/keyrings | .local/share/keyrings/*)
      return 0
      ;;
    .pki | .pki/*)
      return 0
      ;;
    ".config/chromium/Local State" | .config/chromium/*/Login\ Data*)
      return 0
      ;;
    ".config/BraveSoftware/Brave-Browser/Local State")
      return 0
      ;;
    .config/BraveSoftware/Brave-Browser/*/Login\ Data*)
      return 0
      ;;
    ".config/google-chrome/Local State")
      return 0
      ;;
    .config/google-chrome/*/Login\ Data*)
      return 0
      ;;
    ".config/qaxbrowser/Local State" | .config/qaxbrowser/*/Login\ Data*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

validate_remote_archive() {
  local remote_file=$1 listing=$2 entry
  : >"$listing"
  chmod 600 "$listing"

  rclone_vault cat "$remote_file" | tar -tf - >"$listing"
  validate_archive_listing "$listing" "${remote_file##*/}"
}

validate_local_archive() {
  local archive_file=$1 listing=$2 verbose_listing entry_type
  [[ "$archive_file" == /* ]] || die "local archive path must be absolute"
  [[ -f "$archive_file" && ! -L "$archive_file" && -r "$archive_file" ]] ||
    die "local archive is not a readable regular file"
  : >"$listing"
  chmod 600 "$listing"
  tar -tf "$archive_file" >"$listing"
  validate_archive_listing "$listing" "${archive_file##*/}"

  verbose_listing="${listing}.verbose"
  : >"$verbose_listing"
  chmod 600 "$verbose_listing"
  tar -tvf "$archive_file" >"$verbose_listing"
  while IFS= read -r entry_type; do
    case "${entry_type:0:1}" in
      - | d) ;;
      *) die "local archive contains a non-regular entry" ;;
    esac
  done <"$verbose_listing"
}

validate_archive_listing() {
  local listing=$1 archive_name=$2 entry
  [[ -s "$listing" ]] || die "archive is empty: $archive_name"

  while IFS= read -r entry; do
    case "$entry" in
      /* | ../* | */../* | */..) die "archive contains an unsafe path" ;;
    esac
    archive_entry_allowed "$entry" ||
      die "archive contains a path outside the credential allowlist"
  done <"$listing"
}

safe_host_name() {
  local host
  if ! IFS= read -r host </proc/sys/kernel/hostname; then
    host=unknown-host
  fi
  printf '%s' "$host" | tr -c 'A-Za-z0-9._-' '_'
}

perform_backup() {
  local kind=${1:-backup} verify=${2:-yes} manifest_ready=${3:-no}
  local host timestamp archive_name remote_file upload_file file_count

  if [[ "$manifest_ready" != yes ]]; then
    build_manifest || die "no credential files were found"
  fi
  host=$(safe_host_name)
  timestamp=$(date -u +%Y%m%dT%H%M%S.%NZ)
  archive_name="credential-${kind}-${archive_version}-${host}-${timestamp}.tar"
  remote_file="credentialvault:$host/$archive_name"
  upload_file="credentialvault:$host/.partial-${archive_name}-${BASHPID}"
  file_count=$(tr -cd '\0' <"$work_dir/files.nul" | wc -c)

  rclone_vault mkdir "credentialvault:$host"
  tar --create --format=pax --directory="$HOME" --null \
    --files-from="$work_dir/files.nul" --file=- |
    rclone_vault rcat "$upload_file"

  if [[ "$verify" == yes ]]; then
    validate_remote_archive "$upload_file" "$work_dir/upload-listing"
  fi
  rclone_vault moveto "$upload_file" "$remote_file"
  printf 'Encrypted backup verified: %s (%s selected paths)\n' \
    "$archive_name" "$file_count"
}

list_backups() {
  local host
  host=$(safe_host_name)
  rclone_vault lsf "credentialvault:$host" --files-only |
    { grep -E '^credential-(backup|pre-restore)-v1-.*\.tar$' || true; } |
    sort
}

latest_backup() {
  list_backups | { grep '^credential-backup-v1-' || true; } | tail -n 1
}

finish_bitwarden_before_restore() {
  if [[ "$unlocked_here" == 1 ]]; then
    "$bw_bin" lock >/dev/null
    unlocked_here=0
  fi
  unset BW_SESSION
  item_json=""
  webdav_password=""
  crypt_password=""
  crypt_password2=""
}

harden_restored_files() {
  local path
  shopt -s nullglob
  local -a protected_directories=(
    "$HOME/.ssh"
    "$HOME/.gnupg"
    "$HOME/.cli-proxy-api"
    "$HOME/.cloudflared"
    "$HOME/.config/Bitwarden CLI"
    "$HOME/.config/bitwarden"
    "$HOME/.config/gcloud"
    "$HOME/.config/gh"
    "$HOME/.config/rclone"
    "$HOME/.cnb"
    "$HOME/.local/share/keyrings"
    "$HOME/.pki"
  )
  for path in "${protected_directories[@]}"; do
    [[ -d "$path" ]] && chmod 700 "$path"
  done
  for path in "$HOME/.ssh/id_ed25519" "$HOME/.ssh/id_rsa"; do
    [[ -f "$path" ]] && chmod 400 "$path"
  done
  for path in \
    "$HOME/.ssh/config" \
    "$HOME/.ssh/known_hosts" \
    "$HOME/.ssh/authorized_keys"; do
    [[ -f "$path" ]] && chmod 600 "$path"
  done
  for path in "$HOME/.ssh/id_ed25519.pub" "$HOME/.ssh/id_rsa.pub"; do
    [[ -f "$path" ]] && chmod 644 "$path"
  done

  local -a mode_600=(
    "$HOME/.codex/auth.json"
    "$HOME/.config/cursor/auth.json"
    "$HOME/.grok/auth.json"
    "$HOME/.pi/agent/auth.json"
    "$HOME/.config/bash/extra/private.bash"
    "$HOME/.config/cursor-to-openai.env"
    "$HOME/.cnb/token"
    "$HOME/.config/gh/hosts.yml"
    "$HOME/.config/bitwarden/env"
    "$HOME/.config/Bitwarden CLI/data.json"
    "$HOME/.config/rclone/rclone.conf"
    "$HOME/.config/gcloud/application_default_credentials.json"
    "$HOME/.config/gcloud/credentials.db"
    "$HOME/.config/gcloud/access_tokens.db"
    "$HOME/.local/share/atuin/key"
    "$HOME/.cloudflared/office.env"
  )
  for path in "${mode_600[@]}"; do
    [[ -f "$path" ]] && chmod 600 "$path"
  done
  if [[ -d "$HOME/.gnupg" ]]; then
    find "$HOME/.gnupg" -type d -exec chmod 700 {} +
    find "$HOME/.gnupg" -type f -exec chmod 600 {} +
  fi

  local -a protected_files=(
    "$HOME/.cli-proxy-api/"*.json
    "$HOME/.cloudflared/cert.pem"
    "$HOME/.cloudflared/"*.json
    "$HOME/.cloudflared/"*.env
    "$HOME/.cloudflared/"*token*
    "$HOME/.config/rclone/"*oauth*.json
    "$HOME/.config/chromium/Local State"
    "$HOME/.config/chromium/"*/Login\ Data*
    "$HOME/.config/BraveSoftware/Brave-Browser/Local State"
    "$HOME/.config/BraveSoftware/Brave-Browser/"*/Login\ Data*
    "$HOME/.config/google-chrome/Local State"
    "$HOME/.config/google-chrome/"*/Login\ Data*
    "$HOME/.config/qaxbrowser/Local State"
    "$HOME/.config/qaxbrowser/"*/Login\ Data*
  )
  for path in "${protected_files[@]}"; do
    [[ -f "$path" ]] && chmod 600 "$path"
  done
  for path in "$HOME/.local/share/keyrings" "$HOME/.pki"; do
    if [[ -d "$path" ]]; then
      find "$path" -type d -exec chmod 700 {} +
      find "$path" -type f -exec chmod 600 {} +
    fi
  done
}

perform_restore() {
  local requested=${1:-latest} assume_yes=${2:-no}
  local host archive_name remote_file stage_dir answer

  host=$(safe_host_name)
  if [[ "$requested" == latest ]]; then
    archive_name=$(latest_backup) || die "unable to list remote backups"
    [[ -n "$archive_name" ]] || die "no regular credential backup was found"
  else
    archive_name=$requested
  fi
  case "$archive_name" in
    */* | *..* | *[!A-Za-z0-9._-]*) die "unsafe backup name" ;;
  esac
  [[ "$archive_name" == credential-backup-v1-*.tar ]] ||
    die "restore accepts only a regular v1 backup"

  remote_file="credentialvault:$host/$archive_name"
  validate_remote_archive "$remote_file" "$work_dir/restore-listing"

  if [[ "$assume_yes" != yes ]]; then
    [[ -t 0 ]] || die "restore needs an interactive confirmation or --yes"
    printf 'Restore %s over live credential files? [y/N] ' "$archive_name" >&2
    IFS= read -r answer
    [[ "$answer" == y || "$answer" == Y ]] || die "restore cancelled"
  fi

  printf '%s\n' "Creating an encrypted pre-restore backup first." >&2
  if build_manifest; then
    perform_backup pre-restore yes yes
  else
    printf '%s\n' "No existing credential files found; skipping the pre-restore backup." >&2
  fi

  stage_dir="$work_dir/restore"
  mkdir -p "$stage_dir"
  chmod 700 "$stage_dir"
  rclone_vault cat "$remote_file" |
    tar --extract --file=- --directory="$stage_dir" --no-same-owner

  finish_bitwarden_before_restore
  shopt -s dotglob nullglob
  local -a staged_entries=("$stage_dir"/*)
  ((${#staged_entries[@]} > 0)) || die "validated archive extracted no files"
  cp -a --no-preserve=ownership "${staged_entries[@]}" "$HOME/"
  harden_restored_files
  printf 'Restore completed from: %s\n' "$archive_name"
  printf '%s\n' "Restart affected agents and re-open a fresh login shell."
}

perform_local_snapshot() {
  local destination_dir=$1 host timestamp archive_name partial_file archive_file
  [[ "$destination_dir" == /* ]] || die "pre-restore directory must be absolute"
  [[ -d "$destination_dir" && ! -L "$destination_dir" && -w "$destination_dir" ]] ||
    die "pre-restore directory is not a writable real directory"

  if ! build_manifest; then
    printf '%s\n' "No existing credential files found; skipping the pre-restore backup." >&2
    return
  fi

  host=$(safe_host_name)
  timestamp=$(date -u +%Y%m%dT%H%M%S.%NZ)
  archive_name="credential-pre-restore-${archive_version}-${host}-${timestamp}.tar"
  archive_file="$destination_dir/$archive_name"
  partial_file="$destination_dir/.partial-${archive_name}-${BASHPID}"
  local_snapshot_partial=$partial_file
  tar --create --format=pax --directory="$HOME" --null \
    --files-from="$work_dir/files.nul" --file="$partial_file"
  chmod 600 "$partial_file"
  validate_local_archive "$partial_file" "$work_dir/local-snapshot-listing"
  mv -- "$partial_file" "$archive_file"
  local_snapshot_partial=""
  printf 'Encrypted-volume pre-restore backup verified: %s\n' "$archive_name" >&2
}

perform_local_restore() {
  local archive_file=$1 pre_restore_dir=$2 assume_yes=${3:-no}
  local archive_name stage_dir answer

  archive_name=${archive_file##*/}
  [[ "$archive_name" == credential-backup-v1-*.tar ]] ||
    die "local restore accepts only a regular v1 backup"
  validate_local_archive "$archive_file" "$work_dir/local-restore-listing"

  if [[ "$assume_yes" != yes ]]; then
    [[ -t 0 ]] || die "restore needs an interactive confirmation or --yes"
    printf 'Restore %s over live credential files? [y/N] ' "$archive_name" >&2
    IFS= read -r answer
    [[ "$answer" == y || "$answer" == Y ]] || die "restore cancelled"
  fi

  perform_local_snapshot "$pre_restore_dir"

  stage_dir="$work_dir/restore"
  mkdir -p "$stage_dir"
  chmod 700 "$stage_dir"
  tar --extract --file="$archive_file" --directory="$stage_dir" --no-same-owner

  shopt -s dotglob nullglob
  local -a staged_entries=("$stage_dir"/*)
  ((${#staged_entries[@]} > 0)) || die "validated archive extracted no files"
  cp -a --no-preserve=ownership "${staged_entries[@]}" "$HOME/"
  harden_restored_files
  printf 'Restore completed from encrypted USB archive: %s\n' "$archive_name"
  printf '%s\n' "Restart affected agents and re-open a fresh login shell."
}

main() {
  local command=${1:-} requested=latest assume_yes=no argument
  local archive_file="" pre_restore_dir=""

  if [[ -z "$command" ]]; then
    choose_action command
    set -- "$command"
  fi
  case "$command" in
    -h | --help | help)
      usage
      return
      ;;
  esac

  require_executable jq
  prepare_runtime

  case "$command" in
    backup)
      [[ $# == 1 ]] || die "backup takes no arguments"
      require_executable "$rclone_bin"
      load_credentials
      perform_backup backup yes
      ;;
    list)
      [[ $# == 1 ]] || die "list takes no arguments"
      require_executable "$rclone_bin"
      load_credentials
      list_backups
      ;;
    restore)
      require_executable "$rclone_bin"
      shift
      for argument in "$@"; do
        case "$argument" in
          --yes) assume_yes=yes ;;
          latest) requested=latest ;;
          -*) die "unknown restore option: $argument" ;;
          *)
            [[ "$requested" == latest ]] || die "only one backup name is allowed"
            requested=$argument
            ;;
        esac
      done
      load_credentials
      perform_restore "$requested" "$assume_yes"
      ;;
    restore-local)
      shift
      while (($#)); do
        argument=$1
        shift
        case "$argument" in
          --yes) assume_yes=yes ;;
          --pre-restore-dir)
            (($#)) || die "--pre-restore-dir requires a directory"
            pre_restore_dir=$1
            shift
            ;;
          -*) die "unknown restore-local option: $argument" ;;
          *)
            [[ -z "$archive_file" ]] || die "only one local archive is allowed"
            archive_file=$argument
            ;;
        esac
      done
      [[ -n "$archive_file" ]] || die "restore-local requires an archive path"
      [[ -n "$pre_restore_dir" ]] || die "restore-local requires --pre-restore-dir"
      perform_local_restore "$archive_file" "$pre_restore_dir" "$assume_yes"
      ;;
    *)
      usage >&2
      exit 2
      ;;
  esac
}

main "$@"
