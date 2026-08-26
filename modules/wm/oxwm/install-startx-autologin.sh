# Autologin tty1 as Designers and start X via startx before LightDM /
# AccountsService can claim the seat (UOS / Deepin).
# Requires passwordless or interactive sudo for system paths.
#
# UOS systemd 241 ignores instance drop-ins under carlos.p@example.net.d/
# (DropInPaths stays empty). Use the template path getty@.service.d/ instead.

if [[ -e /etc/NIXOS ]]; then
  echo "NixOS uses services.getty.autologinUser in nixos/desktop.nix; do not install /sbin/agetty drop-ins (nixpkgs#429775)." >&2
  exit 0
fi

USER_NAME="${SUDO_USER:-${USER:-Designers}}"
GETTY_DROPIN_DIR=/etc/systemd/system/getty@.service.d
GETTY_DROPIN="${GETTY_DROPIN_DIR}/autologin-startx.conf"
STALE_INSTANCE_DROPIN_DIR=/etc/systemd/system/carlos.p@example.net.d
LIGHTDM_UNIT=lightdm.service

if ! getent passwd "$USER_NAME" >/dev/null; then
  echo "user not found: $USER_NAME" >&2
  exit 1
fi

sudo mkdir -p "$GETTY_DROPIN_DIR"
sudo tee "$GETTY_DROPIN" >/dev/null <<EOF
[Unit]
# Win the race against the display manager and account services.
Before=lightdm.service display-manager.service accounts-daemon.service deepin-accounts-daemon.service
After=systemd-user-sessions.service

[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin ${USER_NAME} --noclear %I \$TERM
Type=idle
EOF

# Remove the ineffective instance drop-in if a prior install left it behind.
if [ -d "$STALE_INSTANCE_DROPIN_DIR" ]; then
  sudo rm -rf "$STALE_INSTANCE_DROPIN_DIR"
fi

# Keep LightDM from grabbing the GPU / VT on the next boot (do not stop it
# here — that would kill the current graphical session).
if systemctl cat "$LIGHTDM_UNIT" >/dev/null 2>&1; then
  sudo systemctl disable "$LIGHTDM_UNIT" 2>/dev/null || true
  sudo systemctl mask "$LIGHTDM_UNIT" 2>/dev/null || true
fi

# LightDM-only force unit is unused on the startx path.
if systemctl cat oxwm-force-session.service >/dev/null 2>&1; then
  sudo systemctl disable oxwm-force-session.service 2>/dev/null || true
fi

sudo systemctl daemon-reload
sudo systemctl enable getty@tty1.service

if ! systemctl show getty@tty1.service -p DropInPaths --value | grep -q 'getty@\.service\.d/autologin-startx.conf'; then
  echo "getty@.service.d drop-in not loaded; check systemd daemon-reload" >&2
  exit 1
fi

echo "Installed tty1 autologin for ${USER_NAME}; LightDM masked for next boot."
echo "Login shell must run startx on VT1 (Home Manager oxwm profile hook)."
echo "Reboot to verify: getty → Designers → startx → oxwm"
