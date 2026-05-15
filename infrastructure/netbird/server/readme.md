# Netbird Control Plane (Server)

This folder contains the configuration to host your own [Netbird](https://netbird.io/) Control Plane (Management, Signal, and Dashboard).

Self-hosting the control plane gives you full control over your network and data privacy.

## Prerequisites

- **Public Domain**: You need a domain name (e.g., `netbird.example.com`) pointing to your server.
- **Reverse Proxy**: Netbird requires a reverse proxy (like Nginx Proxy Manager) to handle HTTPS and gRPC.
- **Ports**: Ensure ports `443` (TCP) and `3478` (UDP for STUN) are open and reachable.

## Installation

1. Run the installation script:
   ```bash
   chmod +x install.sh
   ./install.sh
   ```
2. Follow the prompts to enter your domain name.
3. Configure your reverse proxy (e.g., Nginx Proxy Manager) to point to the dashboard and management ports.

### Nginx Proxy Manager Configuration

If you use the `nginx-reverse-proxy` from this repo, create a Proxy Host for your domain:
- **Forward Hostname**: `netbird-dashboard`
- **Forward Port**: `80`
- **SSL**: Enable "HTTP/2 Support" (Required for gRPC).

**Advanced Configuration (Paste in NPM "Advanced" tab):**
```nginx
# Required for long-lived connections (gRPC and WebSocket)
client_header_timeout 1d;
client_body_timeout 1d;

# WebSocket connections (relay, signal, management)
location ~ ^/(relay|ws-proxy/) {
    proxy_pass http://netbird-server:80;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_read_timeout 1d;
}

# Native gRPC (signal + management)
location ~ ^/(signalexchange\.SignalExchange|management\.ManagementService)/ {
    grpc_pass grpc://netbird-server:80;
    grpc_read_timeout 1d;
    grpc_send_timeout 1d;
    grpc_socket_keepalive on;
}

# HTTP routes (API + OAuth2)
location ~ ^/(api|oauth2)/ {
    proxy_pass http://netbird-server:80;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

## First Login
After installation, navigate to `https://netbird.your-domain.com/setup` to create your first admin user.

