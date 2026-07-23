# Cloudflared-Only SSH Exposure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enable the UOS OpenSSH server on loopback only and expose it exclusively through one authenticated Cloudflare Tunnel ingress.

**Architecture:** Home Manager installs only the `cloudflared` client. A repository-owned systemd override starts the existing UOS sshd with `ListenAddress=127.0.0.1`, and the named Cloudflare Tunnel forwards its sole hostname to `ssh://127.0.0.1:22`.

**Tech Stack:** Nix, Home Manager, OpenSSH, systemd, Cloudflare Tunnel, Cloudflare Access

## Global Constraints

- Keep changes small and focused.
- Do not modify existing SSH authentication policy.
- Do not expose SSH on a LAN or wildcard address.
- Do not commit or print Cloudflare credentials, tunnel tokens, SSH private keys, hostnames not approved for publication, or account identifiers.
- Do not update `flake.lock`.
- Stop before Cloudflare activation until the operator supplies the intended hostname and completes browser authentication.

---

### Task 1: Keep Only the Cloudflared Client

**Files:**
- Modify: `profiles/work/home.nix`

**Interfaces:**
- Consumes: Existing `networkPackages` list and `home.packages` composition.
- Produces: A Home Manager activation package containing `cloudflared` but not Cloudflare WARP or Tailscale.

- [ ] **Step 1: Record the current package declarations**

Run:

```bash
grep -n -E 'cloudflared|cloudflare-warp|tailscale' profiles/work/home.nix
```

Expected: one line for each of `cloudflared`, `cloudflare-warp`, and
`tailscale`.

- [ ] **Step 2: Restrict the package group to cloudflared**

Change the binding to:

```nix
  networkPackages = with pkgs; [
    cloudflared
  ];
```

- [ ] **Step 3: Format the edited profile**

Run:

```bash
nix develop --command alejandra profiles/work/home.nix
```

Expected: exit status 0.

- [ ] **Step 4: Build the active Home Manager output**

Run:

```bash
nix build '.#homeConfigurations."Designers".activationPackage' --no-link --no-update-lock-file
```

Expected: exit status 0 and no `flake.lock` change.

- [ ] **Step 5: Confirm package scope**

Run:

```bash
grep -n -E 'cloudflared|cloudflare-warp|tailscale' profiles/work/home.nix
```

Expected: exactly one match, for `cloudflared`.

- [ ] **Step 6: Commit the focused package change**

Run:

```bash
git add profiles/work/home.nix
git commit -m "Restrict network client to cloudflared"
```

Expected: a commit containing only `profiles/work/home.nix`.

---

### Task 2: Define the Loopback-Only SSH Service Override

**Files:**
- Create: `system/ssh/ssh.service.d/cloudflared-only.conf`

**Interfaces:**
- Consumes: UOS `/lib/systemd/system/ssh.service` and `/usr/sbin/sshd`.
- Produces: A systemd override that retains `/etc/ssh/sshd_config` while forcing sshd to listen only on IPv4 loopback port 22.

- [ ] **Step 1: Add the repository-owned override**

Create `system/ssh/ssh.service.d/cloudflared-only.conf` with:

```ini
[Service]
ExecStart=
ExecStart=/usr/sbin/sshd -D -o ListenAddress=127.0.0.1 -o Port=22
```

- [ ] **Step 2: Verify the executable and base configuration**

Run:

```bash
test -x /usr/sbin/sshd
/usr/sbin/sshd -t
```

Expected: both commands exit 0 with no output.

- [ ] **Step 3: Check the override syntax in an isolated unit search path**

Run:

```bash
systemd-analyze verify \
  /lib/systemd/system/ssh.service \
  system/ssh/ssh.service.d/cloudflared-only.conf
```

Expected: exit status 0 with no SSH unit error.

- [ ] **Step 4: Commit the override source**

Run:

```bash
git add system/ssh/ssh.service.d/cloudflared-only.conf
git commit -m "Bind SSH service to loopback"
```

Expected: a commit containing only the new systemd override.

---

### Task 3: Install and Enable the UOS SSH Service

**Files:**
- Install: `/etc/systemd/system/ssh.service.d/cloudflared-only.conf`
- Preserve: `/etc/ssh/sshd_config`

**Interfaces:**
- Consumes: The committed override from Task 2 and installed `openssh-server`.
- Produces: An enabled, active `ssh.service` listening only on `127.0.0.1:22`.

- [ ] **Step 1: Confirm the package and current service state**

Run:

```bash
dpkg-query -W -f='${Status}\n' openssh-server
systemctl is-enabled ssh.service || true
systemctl is-active ssh.service || true
```

Expected: `install ok installed`, followed initially by `masked` and
`inactive`.

- [ ] **Step 2: Install the override with root authorization**

Run:

```bash
pkexec install -D -m 0644 \
  system/ssh/ssh.service.d/cloudflared-only.conf \
  /etc/systemd/system/ssh.service.d/cloudflared-only.conf
```

Expected: graphical authentication followed by exit status 0.

- [ ] **Step 3: Validate sshd before service activation**

Run:

```bash
pkexec /usr/sbin/sshd -t
```

Expected: exit status 0 with no output. Stop here on any error.

- [ ] **Step 4: Unmask and enable the service**

Run:

```bash
pkexec systemctl unmask ssh.service
pkexec systemctl daemon-reload
pkexec systemctl enable --now ssh.service
```

Expected: `ssh.service` becomes enabled and starts successfully.

- [ ] **Step 5: Verify service and listener state**

Run:

```bash
systemctl is-enabled ssh.service
systemctl is-active ssh.service
systemctl show ssh.service -p ExecStart --value
ss -ltnp 'sport = :22'
```

Expected:

- The first two commands print `enabled` and `active`.
- `ExecStart` includes `ListenAddress=127.0.0.1` and `Port=22`.
- The only TCP port 22 listener is `127.0.0.1:22`; there is no `0.0.0.0:22`,
  `[::]:22`, LAN address, or public address.

- [ ] **Step 6: Test loopback SSH transport**

Run:

```bash
ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new \
  -o ConnectTimeout=5 127.0.0.1 true
```

Expected: the TCP connection reaches sshd. Exit status may be 255 with
`Permission denied` if no authorized key is configured; `Connection refused`
or a timeout is a failure.

---

### Task 4: Create the SSH-Only Cloudflare Tunnel

**Files:**
- Create outside Git: `$HOME/.cloudflared/config.yml`
- Create outside Git: `$HOME/.cloudflared/$SSH_TUNNEL_UUID.json`

**Interfaces:**
- Consumes: An operator-supplied Cloudflare-managed SSH hostname, browser login, and active loopback sshd from Task 3.
- Produces: One named tunnel whose only hostname ingress forwards to `ssh://127.0.0.1:22`, plus a rejecting catch-all.

- [ ] **Step 1: Obtain and validate the intended hostname**

Ask the operator for the complete hostname, assign the response without
printing any credentials, and validate its shape:

```bash
read -r -p 'Cloudflare SSH hostname: ' SSH_TUNNEL_HOSTNAME
case "$SSH_TUNNEL_HOSTNAME" in
  *.*) ;;
  *) echo 'A fully qualified hostname is required' >&2; exit 1 ;;
esac
```

Expected: a fully qualified hostname in a Cloudflare-managed zone.

- [ ] **Step 2: Authenticate cloudflared**

Run:

```bash
cloudflared tunnel login
```

Expected: the browser authorization succeeds and
`$HOME/.cloudflared/cert.pem` exists. Do not display its contents.

- [ ] **Step 3: Create the named tunnel and capture its UUID**

Run:

```bash
cloudflared tunnel create ssh-only
cloudflared tunnel list
```

Expected: a tunnel named `ssh-only` and its credential JSON exist under
`$HOME/.cloudflared`. Record the UUID from the command output as
`SSH_TUNNEL_UUID`; do not display the credential file.

- [ ] **Step 4: Create the private tunnel configuration**

Create `$HOME/.cloudflared/config.yml` with mode `0600` and this exact
structure, substituting the values obtained in Steps 1 and 3:

```yaml
tunnel: SSH_TUNNEL_UUID
credentials-file: /home/Designers/.cloudflared/SSH_TUNNEL_UUID.json

ingress:
  - hostname: SSH_TUNNEL_HOSTNAME
    service: ssh://127.0.0.1:22
  - service: http_status:404
```

Replace both `SSH_TUNNEL_UUID` strings with the recorded UUID and replace
`SSH_TUNNEL_HOSTNAME` with the approved hostname. Do not add the file to Git.

- [ ] **Step 5: Restrict permissions and validate ingress**

Run:

```bash
chmod 0600 "$HOME/.cloudflared/config.yml"
cloudflared tunnel ingress validate
stat -c '%a %n' "$HOME/.cloudflared/config.yml"
```

Expected: validation succeeds and `stat` prints mode `600`.

- [ ] **Step 6: Route the hostname**

Run:

```bash
cloudflared tunnel route dns ssh-only "$SSH_TUNNEL_HOSTNAME"
```

Expected: Cloudflare creates the DNS route for the named tunnel.

- [ ] **Step 7: Create a Cloudflare Access policy**

In the Cloudflare Zero Trust dashboard, add a self-hosted application for
`SSH_TUNNEL_HOSTNAME` and an Allow policy restricted to the intended user
identity. Do not create a bypass or public allow policy.

Expected: unauthenticated requests are denied and the approved identity can
complete Access authentication.

---

### Task 5: Run and Verify the Tunnel

**Files:**
- Consume outside Git: `$HOME/.cloudflared/config.yml`
- Consume outside Git: `$HOME/.cloudflared/$SSH_TUNNEL_UUID.json`

**Interfaces:**
- Consumes: The validated tunnel configuration and Cloudflare Access policy.
- Produces: A running SSH-only tunnel and end-to-end evidence that no direct LAN SSH exposure exists.

- [ ] **Step 1: Start the tunnel interactively for initial validation**

Run:

```bash
cloudflared tunnel run ssh-only
```

Expected: cloudflared establishes healthy connections and reports no ingress
or credential error. Keep this process running during the next checks.

- [ ] **Step 2: Configure the remote SSH client**

On the remote client, add:

```sshconfig
Host SSH_TUNNEL_HOSTNAME
  ProxyCommand cloudflared access ssh --hostname %h
```

Replace `SSH_TUNNEL_HOSTNAME` with the approved hostname.

- [ ] **Step 3: Verify authenticated remote access**

On the remote client, run:

```bash
ssh DESIGNERS_USER@SSH_TUNNEL_HOSTNAME
```

Replace `DESIGNERS_USER` with the host's approved SSH account name and
`SSH_TUNNEL_HOSTNAME` with the approved hostname.

Expected: Cloudflare Access authenticates the approved identity and SSH
reaches the UOS host.

- [ ] **Step 4: Verify direct LAN access is unavailable**

From another LAN device, run:

```bash
nc -vz -w 5 UOS_LAN_ADDRESS 22
```

Replace `UOS_LAN_ADDRESS` with the UOS host's LAN IP address.

Expected: connection refused or timeout. A successful TCP connection is a
failure and must stop deployment.

- [ ] **Step 5: Reconfirm the host listener**

On the UOS host, run:

```bash
ss -ltnp 'sport = :22'
```

Expected: only `127.0.0.1:22`.

- [ ] **Step 6: Stop the interactive tunnel after validation**

Press `Ctrl-C` in the terminal running `cloudflared tunnel run ssh-only`.

Expected: the foreground cloudflared process exits cleanly before the managed
user service is enabled.

---

### Task 6: Enable the Validated Tunnel as a User Service

**Files:**
- Modify: `profiles/work/home.nix`

**Interfaces:**
- Consumes: The validated `$HOME/.cloudflared/config.yml` from Task 4.
- Produces: A Home Manager-managed `cloudflared-ssh.service` that starts the SSH-only tunnel with the user's desktop session.

- [ ] **Step 1: Add the cloudflared user service**

Add this service to the Home Manager module:

```nix
  systemd.user.services.cloudflared-ssh = {
    Unit = {
      Description = "Cloudflare Tunnel for loopback SSH";
      ConditionPathExists = "%h/.cloudflared/config.yml";
      After = ["network-online.target"];
      Wants = ["network-online.target"];
    };
    Service = {
      ExecStart = "${pkgs.cloudflared}/bin/cloudflared --config %h/.cloudflared/config.yml tunnel run";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = ["default.target"];
  };
```

- [ ] **Step 2: Format and build the Home Manager output**

Run:

```bash
nix develop --command alejandra profiles/work/home.nix
nix build '.#homeConfigurations."Designers".activationPackage' --no-link --no-update-lock-file
```

Expected: both commands exit 0 and `flake.lock` remains unchanged.

- [ ] **Step 3: Activate the validated configuration**

Run:

```bash
env PATH=/nix/var/nix/profiles/default/bin:$HOME/.nix-profile/bin \
  home-manager switch --flake .#Designers -b hm-bak
```

Expected: Home Manager activation succeeds and reloads the user service
manager.

- [ ] **Step 4: Start and inspect the managed tunnel**

Run:

```bash
systemctl --user enable --now cloudflared-ssh.service
systemctl --user is-enabled cloudflared-ssh.service
systemctl --user is-active cloudflared-ssh.service
journalctl --user -u cloudflared-ssh.service -n 50 --no-pager
```

Expected: the service is `enabled` and `active`; logs show healthy tunnel
connections and contain no credential or ingress error.

- [ ] **Step 5: Repeat exposure checks**

Run on the UOS host:

```bash
ss -ltnp 'sport = :22'
```

Expected: only `127.0.0.1:22`.

From another LAN device, repeat:

```bash
nc -vz -w 5 UOS_LAN_ADDRESS 22
```

Replace `UOS_LAN_ADDRESS` with the UOS host's LAN IP address.

Expected: connection refused or timeout.

- [ ] **Step 6: Commit the managed service**

Run:

```bash
git add profiles/work/home.nix
git commit -m "Run SSH tunnel as user service"
```

Expected: a focused commit containing only the user-service addition.
