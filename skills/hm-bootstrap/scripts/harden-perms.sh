#!/usr/bin/env bash
set -euo pipefail

u="$(id -un)"
g="$(id -gn)"
h="$HOME"

fix_owner() {
  local p="$1"
  [ -e "$p" ] || return 0
  chown -R "$u:$g" "$p"
}

for p in "$h/.ssh" "$h/.gnupg" "$h/.password-store" "$h/.config/gh" "$h/.local/share/keyrings"; do
  fix_owner "$p"
done

if [ -d "$h/.ssh" ]; then
  chmod 700 "$h/.ssh"
  find "$h/.ssh" -type d -exec chmod 700 {} +
  find "$h/.ssh" -type f -exec chmod 600 {} +
  find "$h/.ssh" -type f \( -name '*.pub' -o -name 'known_hosts' -o -name 'known_hosts.old' \) -exec chmod 644 {} +
  [ -f "$h/.ssh/authorized_keys" ] && chmod 600 "$h/.ssh/authorized_keys"
fi

if [ -d "$h/.gnupg" ]; then
  chmod 700 "$h/.gnupg"
  find "$h/.gnupg" -type d -exec chmod 700 {} +
  find "$h/.gnupg" -type f -exec chmod 600 {} +
fi

if [ -d "$h/.password-store" ]; then
  chmod 700 "$h/.password-store"
  find "$h/.password-store" -type d -exec chmod 700 {} +
  find "$h/.password-store" -type f -exec chmod 600 {} +
fi

if [ -d "$h/.config/gh" ]; then
  chmod 700 "$h/.config/gh"
  find "$h/.config/gh" -type d -exec chmod 700 {} +
  find "$h/.config/gh" -type f -exec chmod 600 {} +
fi

if [ -d "$h/.local/share/keyrings" ]; then
  chmod 700 "$h/.local/share/keyrings" || true
  find "$h/.local/share/keyrings" -type d -exec chmod 700 {} + || true
  find "$h/.local/share/keyrings" -type f -exec chmod 600 {} +
fi

for f in "$h/.netrc" "$h/.pypirc" "$h/.npmrc" "$h/.docker/config.json" "$h/.git-credentials"; do
  [ -f "$f" ] || continue
  chown "$u:$g" "$f"
  chmod 600 "$f"
done

echo "Permissions hardening complete."
