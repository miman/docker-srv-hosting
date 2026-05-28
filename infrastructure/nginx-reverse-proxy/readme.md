# NGINX proxy manager

[NGINX proxy manager](https://nginxproxymanager.com/) is a easy to use reverse proxy manager.

It is used to expose one entry point and have subdomains for your servers.

It can also act as an HTTPS endpoint handing your domain certificate

## Local certificate

If you don't want to expose port 80/443 to handle certificates you can follow these steps: [local-cert](local-cert.md)

## Troubleshooting

### Podman: Permission Denied on Port 80/443 (`bind() failed: 13`)

If you see an error like this when starting the container:
```
nginx: [emerg] bind() to 0.0.0.0:80 failed (13: Permission denied)
```

#### Why it happens:
By default, the Linux kernel prevents non-root (unprivileged) users from binding to privileged ports below `1024` (such as `80` and `443`). Since **rootless Podman** runs under your normal user account rather than root, the kernel blocks the container from binding to those host ports, even when using host network mode (`network_mode: host`).

#### How to fix it:
You need to configure the host system to lower the starting unprivileged port threshold to `80` (or `0` to allow all). Run the following commands on your Ubuntu server:

1. **Apply the change immediately:**
   ```bash
   sudo sysctl net.ipv4.ip_unprivileged_port_start=80
   ```

2. **Make the change persistent (persists after reboots):**
   ```bash
   echo "net.ipv4.ip_unprivileged_port_start=80" | sudo tee /etc/sysctl.d/50-podman-ports.conf
   sudo sysctl --system
   ```

3. **Restart the proxy service:**
   ```bash
   ./install.sh
   ```

