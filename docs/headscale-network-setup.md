# Headscale Network Setup

## Needs
I want to secure my network using **Headscale**, which is a self-hosted, open-source implementation of the Tailscale control server. It allows you to create a secure VPN-like network (WireGuard-based) for your devices.

**Key Objectives:**
- Use a single DNS name (with wildcard) to access local services securely via HTTPS.
- Maintain consistent access via the same DNS name whether on the local LAN or connected via Headscale (VPN).
- Minimize the number of Tailscale clients on the LAN by using a **Subnet Router**.
- Ensure NGINX Proxy Manager (NPM) sees the actual client IP (100.64.x.x) instead of the gateway IP.
- Map a public DNS name to the Headscale control plane for external device connectivity.

## Examples used in this page

| Thing | Example | Description |
| :--- | :--- | :--- |
| **External IP** | `123.456.789.123` | Your home/office public IP address. |
| **Internal IP** | `192.168.10.122` | The local static IP of your server running NPM and Headscale. |
| **External DNS** | `headscale.example.com` | DNS name pointing to your External IP for the Headscale control plane. |
| **Internal DNS** | `*.lan.example.com` | Wildcard DNS pointing to your Internal IP for local services. |

## Steps

### 1. Configure External DNS for the Control Plane
You need a public DNS record (e.g., through DuckDNS, Cloudflare, etc.) that points to your public IP. This allows your devices to find and connect to your Headscale server from anywhere.

*   **Example:** `headscale.external.duckdns.org` → `123.456.789.123`
*   *Note:* Ensure port `8080` (or your configured Headscale port) and `443` (for the proxy) are forwarded on your router if necessary.

### 2. Configure Internal/Wildcard DNS for Services
Create a wildcard DNS record pointing to your server's internal static IP. This facilitates consistent HTTPS access.

*   **Example:** `*.internal.duckdns.org` → `192.168.10.122`

### 3. Install Headscale
Install Headscale using the provided automation script. This script handles the Docker setup and initial configuration.

```bash
cd headscale
./install.sh
```
*During installation, you will be prompted for your domain name and version. The script will also check for local Tailscale conflicts.*

### 4. Install NGINX Proxy Manager
NGINX Proxy Manager will act as the gateway for your services and the Headscale control plane.

*   Follow the detailed [NGINX Proxy Manager Setup](nginx-proxy-mgr-setup.md).
*   **Crucial:** Create a Proxy Host in NPM for `headscale.external.duckdns.org` pointing to `http://headscale:8080`.

### 5. Set up the Subnet Router
To access your entire LAN without installing Tailscale on every single device, you can configure your server as a **Subnet Router**.

1.  **Install the Tailscale client** on the same server where Headscale/NPM is running:
    ```bash
    cd scripts
    ./install-tailscale-client.sh
    ```

2.  **Authenticate and advertise routes:**
    Tell Headscale that this node can reach your local network (`192.168.10.0/24`).
    ```bash
    tailscale up --login-server https://headscale.external.duckdns.org --advertise-routes=192.168.10.0/24
    ```

3.  **Enable the Route in Headscale:**
    You must explicitly approve the advertised route in Headscale.
    *   Find the node ID: `docker exec headscale headscale nodes list`
    *   Enable the route:
    ```bash
    docker exec headscale headscale routes enable -i <node-id> -r 192.168.10.0/24
    ```

### 6. Connect your Devices
Now, install the Tailscale client on your phone or laptop. Use your Headscale URL (`https://headscale.external.duckdns.org`) as the login server. Once connected, you can access `service.internal.duckdns.org` from anywhere!

