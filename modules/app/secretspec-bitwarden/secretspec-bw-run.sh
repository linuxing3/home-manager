#!/usr/bin/env bash
set -euo pipefail

readonly program_name="secretspec-bw-run"
readonly default_manifest="${XDG_CONFIG_HOME:-$HOME/.config}/secretspec/home-config.toml"

manifest=${SECRETSPEC_BW_FILE:-$default_manifest}
reason=${SECRETSPEC_REASON:-}
profile=${SECRETSPEC_PROFILE:-}
session=${BW_SESSION:-}
master_password=""
unlocked_here=0
bw_bin=""
jq_bin=""
secretspec_bin=""
env_bin=""

# Do not let an inherited session reach helper processes by accident. It is
# passed explicitly only to Bitwarden and SecretSpec children below.
unset BW_SESSION

usage() {
  cat <<'EOF'
Run a command with secrets resolved from Bitwarden.

Usage:
  secretspec-bw-run [--file FILE] [--profile NAME] [--reason TEXT] -- COMMAND [ARG...]

Options:
  -f, --file FILE    SecretSpec manifest to use
  -P, --profile NAME Resolve a named SecretSpec profile
      --reason TEXT  Audit reason passed to SecretSpec
  -h, --help         Show this help

The default manifest is:
  $XDG_CONFIG_HOME/secretspec/home-config.toml

The Bitwarden master password is read locally with masked input when the vault
is locked. BW_SESSION is removed before COMMAND starts. If this wrapper unlocks
the vault, it locks the vault again when COMMAND exits.
EOF
}

die() {
  printf '%s: %s\n' "$program_name" "$*" >&2
  exit 1
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

cleanup() {
  local exit_status=$?

  trap - EXIT HUP INT TERM
  master_password=""

  if [[ "$unlocked_here" == 1 && -n "$session" && -x "$bw_bin" ]]; then
    BW_SESSION="$session" "$bw_bin" lock >/dev/null 2>&1 || true
  fi
  session=""

  return "$exit_status"
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

require_executable() {
  local name=$1 target=$2 resolved
  resolved=$(command -v "$name") || die "required command is not available: $name"
  printf -v "$target" '%s' "$resolved"
}

bitwarden_status() {
  local status_json

  if [[ -n "$session" ]]; then
    status_json=$(BW_SESSION="$session" "$bw_bin" status) ||
      die "unable to query Bitwarden status"
  else
    status_json=$("$bw_bin" status) || die "unable to query Bitwarden status"
  fi

  printf '%s' "$status_json" | "$jq_bin" -er '.status | strings' ||
    die "Bitwarden returned an invalid status"
}

unlock_bitwarden() {
  local status new_session
  status=$(bitwarden_status)

  case "$status" in
    unlocked)
      [[ -n "$session" ]] || die "Bitwarden reports unlocked without a usable session"
      ;;
    locked)
      printf '\n╭─ Unlock Bitwarden\n' >&2
      read_masked_password '╰─ Master password: ' master_password
      [[ -n "$master_password" ]] || die "Bitwarden master password must not be empty"

      if ! new_session=$(BW_MASTER_PASSWORD="$master_password" \
        "$bw_bin" unlock --passwordenv BW_MASTER_PASSWORD --raw); then
        master_password=""
        die "Bitwarden unlock failed"
      fi
      master_password=""
      [[ -n "$new_session" ]] || die "Bitwarden unlock returned an empty session"

      session=$new_session
      new_session=""
      unlocked_here=1
      ;;
    unauthenticated)
      die "Bitwarden is not logged in; run 'bw login' locally first"
      ;;
    *)
      die "unknown Bitwarden status: $status"
      ;;
  esac
}

while (($# > 0)); do
  case "$1" in
    -f | --file)
      (($# >= 2)) || die "$1 requires a file path"
      manifest=$2
      shift 2
      ;;
    --reason)
      (($# >= 2)) || die "$1 requires text"
      reason=$2
      shift 2
      ;;
    -P | --profile)
      (($# >= 2)) || die "$1 requires a profile name"
      profile=$2
      shift 2
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*)
      die "unknown option: $1"
      ;;
    *)
      break
      ;;
  esac
done

(($# > 0)) || die "no command supplied; run with --help for usage"
[[ -r "$manifest" ]] || die "manifest is not readable: $manifest"

require_executable bw bw_bin
require_executable jq jq_bin
require_executable secretspec secretspec_bin
require_executable env env_bin

unlock_bitwarden
BW_SESSION="$session" "$bw_bin" sync >/dev/null

secretspec_args=(--file "$manifest")
if [[ -n "$reason" ]]; then
  secretspec_args+=(--reason "$reason")
fi
run_args=()
if [[ -n "$profile" ]]; then
  run_args+=(--profile "$profile")
fi

# SecretSpec 0.18 preserves its parent environment for COMMAND. Use env as a
# minimal trusted trampoline so the resolved secrets remain available while
# the Bitwarden session is removed before the requested program starts.
BW_SESSION="$session" "$secretspec_bin" "${secretspec_args[@]}" run "${run_args[@]}" -- \
  "$env_bin" -u BW_SESSION -- "$@"
