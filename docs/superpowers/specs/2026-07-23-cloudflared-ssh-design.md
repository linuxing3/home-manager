# Cloudflared-Only SSH Exposure Design

## Goal

Enable the UOS host's OpenSSH server while ensuring that Cloudflare Tunnel is
the only external path to it.

## Host SSH Service

The installed `openssh-server` package remains the system SSH implementation.
Configure sshd to listen only on `127.0.0.1:22`, validate its configuration
with `sshd -t`, then unmask and enable `ssh.service`.

Binding only to IPv4 loopback prevents direct SSH access from LAN and other
host interfaces. Cloudflared will reach sshd through the same host's loopback
interface.

## Cloudflare Tunnel

Keep `cloudflared` in the Home Manager work profile and remove the unrelated
Cloudflare WARP and Tailscale clients. The operator must supply a hostname
already delegated to their Cloudflare account before tunnel activation.
Configure that hostname as the named tunnel's only ingress:

```yaml
ingress:
  - hostname: ssh.example.com
    service: ssh://127.0.0.1:22
  - service: http_status:404
```

Here `ssh.example.com` is documentation-only; activation substitutes the
operator-provided hostname. The catch-all rule rejects every route not
explicitly assigned to SSH. Tunnel credentials and account-specific
identifiers must remain outside Git and must not be printed in logs.

Remote clients connect through Cloudflare Access using `cloudflared access
ssh`, rather than opening a direct TCP connection to the host.

## Ownership Boundaries

This flake is a standalone Home Manager configuration and cannot manage the
UOS system SSH daemon. Home Manager owns the `cloudflared` client package.
Root-authorized UOS configuration owns sshd installation, listener settings,
and service enablement. Cloudflare owns the tunnel, DNS route, and Access
policy.

## Failure Safety

Validate sshd configuration before restarting or enabling the service. Do not
enable sshd if validation fails. Preserve the current sshd configuration before
editing it, and avoid changing authentication policy as part of this focused
task.

Do not start cloudflared until the named tunnel, hostname, credential file, and
Access policy are available. A missing or invalid tunnel configuration must
leave SSH reachable only from the local host.

## Validation

- Confirm `openssh-server` is installed.
- Confirm `sshd -t` succeeds.
- Confirm `ssh.service` is enabled and active.
- Confirm `sshd` listens on `127.0.0.1:22` and no non-loopback address.
- Format and build the affected Home Manager activation package.
- Validate the Cloudflare ingress configuration.
- Confirm the public hostname reaches SSH through Cloudflare Access.
- Confirm direct LAN connections to TCP port 22 fail.
