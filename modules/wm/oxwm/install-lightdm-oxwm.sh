# Install oxwm as the LightDM auto-login session on UOS.
# Requires passwordless or interactive sudo for system paths.
# Also installs a systemd unit that re-asserts oxwm before LightDM
# (Deepin/AccountsService otherwise rewrites XSession=deepin).

USER_NAME="${SUDO_USER:-${USER:-Designers}}"
HOME_DIR=$(getent passwd "$USER_NAME" | cut -d: -f6)
SESSION_WRAPPER="${HOME_DIR}/.local/bin/oxwm-session"
SYSTEM_SESSION=/usr/share/xsessions/oxwm.desktop
LIGHTDM_CONF=/etc/lightdm/lightdm.conf
ACCOUNTS=/var/lib/AccountsService/users/${USER_NAME}
FORCE_SCRIPT=/usr/local/sbin/oxwm-force-session
FORCE_UNIT=/etc/systemd/system/oxwm-force-session.service
LIGHTDM_DROPIN_DIR=/etc/systemd/system/lightdm.service.d
LIGHTDM_DROPIN="${LIGHTDM_DROPIN_DIR}/oxwm-force-session.conf"

if [[ ! -x $SESSION_WRAPPER ]]; then
  echo "missing oxwm-session at $SESSION_WRAPPER (activate Home Manager first)" >&2
  exit 1
fi

sudo tee "$SYSTEM_SESSION" >/dev/null <<EOF
[Desktop Entry]
Name=oxwm
Comment=OXWM dynamic window manager
Exec=${SESSION_WRAPPER}
TryExec=${SESSION_WRAPPER}
Type=Application
DesktopNames=oxwm
X-LightDM-DesktopName=oxwm
EOF

# Point LightDM autologin at oxwm (dedupe keys first).
if [[ -f $LIGHTDM_CONF ]]; then
  sudo cp -a "$LIGHTDM_CONF" "${LIGHTDM_CONF}.bak.$(date +%Y%m%d%H%M%S)"
  sudo awk '
    BEGIN { au=0; us=0; as=0 }
    /^autologin-user=/ { if (!au++) print "autologin-user='"${USER_NAME}"'"; next }
    /^user-session=/ { if (!us++) print "user-session=oxwm"; next }
    /^#?autologin-session=/ { if (!as++) print "autologin-session=oxwm"; next }
    { print }
    END {
      if (!au) print "autologin-user='"${USER_NAME}"'"
      if (!us) print "user-session=oxwm"
      if (!as) print "autologin-session=oxwm"
    }
  ' "$LIGHTDM_CONF" | sudo tee "${LIGHTDM_CONF}.oxwm.tmp" >/dev/null
  sudo mv "${LIGHTDM_CONF}.oxwm.tmp" "$LIGHTDM_CONF"
fi

sudo tee "$FORCE_SCRIPT" >/dev/null <<EOF
#!/bin/sh
# Re-assert Designers LightDM session = oxwm (Deepin likes to flip it back).
set -eu
ACCOUNTS='${ACCOUNTS}'
DMRC='${HOME_DIR}/.dmrc'
USER_NAME='${USER_NAME}'

chattr -i "\$ACCOUNTS" 2>/dev/null || true
if [ -f "\$ACCOUNTS" ]; then
  if grep -q '^XSession=' "\$ACCOUNTS"; then
    sed -i 's/^XSession=.*/XSession=oxwm/' "\$ACCOUNTS"
  else
    echo 'XSession=oxwm' >> "\$ACCOUNTS"
  fi
else
  printf '%s\n' '[User]' 'XSession=oxwm' 'SystemAccount=false' > "\$ACCOUNTS"
fi
chattr +i "\$ACCOUNTS" 2>/dev/null || true

printf '%s\n' '[Desktop]' 'Session=oxwm' > "\$DMRC"
chown "\${USER_NAME}:\${USER_NAME}" "\$DMRC" 2>/dev/null || true
chmod 644 "\$DMRC" 2>/dev/null || true
EOF
sudo chmod 755 "$FORCE_SCRIPT"
sudo "$FORCE_SCRIPT"

sudo tee "$FORCE_UNIT" >/dev/null <<EOF
[Unit]
Description=Force LightDM Designers session to oxwm
DefaultDependencies=no
Before=lightdm.service display-manager.service
After=local-fs.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=${FORCE_SCRIPT}

[Install]
WantedBy=multi-user.target
EOF

sudo mkdir -p "$LIGHTDM_DROPIN_DIR"
sudo tee "$LIGHTDM_DROPIN" >/dev/null <<EOF
[Unit]
After=oxwm-force-session.service
Requires=oxwm-force-session.service
EOF

sudo systemctl daemon-reload
sudo systemctl enable oxwm-force-session.service
sudo systemctl restart oxwm-force-session.service

echo "Installed LightDM oxwm session for ${USER_NAME} (persistent)."
echo "Reboot or restart lightdm to apply: sudo systemctl restart lightdm"
