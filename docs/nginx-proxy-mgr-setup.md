# NGINX Proxy Manager (NPM) Setup

This page descibes how to configure NGINX Proxy Manager (NPM) to reverse proxy internal and external services.

## Needs
- Use human-readable DNS names (e.g., `hass.internal.example.com`) to access internal services.
- Automate HTTPS (SSL/TLS) termination for all internal and external services.
- Secure access to sensitive services using Access Control Lists (ACLs).

## Examples used in this page

| Thing | Example | Description |
| :--- | :--- | :--- |
| **Internal IP** | `192.168.10.122` | The local static IP of your server running NPM. |
| **Internal DNS** | `*.internal.duckdns.org` | Wildcard DNS record pointing to your internal IP. |

## Setup

### 1. Configure Wildcard DNS
Before starting, ensure you have a wildcard DNS record (e.g., `*.internal.duckdns.org`) pointing to your server's **Internal IP** (`192.168.10.122`). This allows NPM to handle any subdomain you create instantly.

### 2. Install NGINX Proxy Manager
Run the installation script to deploy NPM via Docker Compose.

```bash
cd nginx-reverse-proxy
./install.sh
```
*The default login for a fresh NPM installation is usually `admin@example.com` / `changeme`.*

### 3. Login to NPM
Open your browser and navigate to `http://192.168.10.122:81` (or the port you configured during installation).

Log in with the following username and password: Default username: admin@example.com. Default password: changeme

### 4. Generate a Wildcard SSL Certificate
To enable HTTPS for all subdomains without creating individual certificates:
1.  Go to the **Certificates** tab in NPM.
2.  Click **Add Certificate** > **Let's Encrypt via DNS**.
3.  Enter your wildcard domain in "Domain Names": `*.internal.duckdns.org`
4.  Select your DNS provider (e.g., DuckDNS, Cloudflare)
5. enter your credentials in the **Credentials File Content** field
  ```
  dns_duckdns_token={your-token}
   ```
6. write 120 in **Propagation Seconds**
7.  Agree to the terms and click **Save**.

### 5. Create Proxy Hosts
For each service you want to expose:
1.  Go to the **Hosts** > **Proxy Hosts** tab.
2.  **Domain Names:** `service.internal.duckdns.org`
3.  **Scheme:** `http` or `https` (depending on the destination service).
4.  **Forward IP/Hostname:** The local IP of the container or machine. If the service is in the same Docker network as NPM, you can often use the container name.
5.  **Forward Port:** The port the service listens on.
6.  **SSL Tab:** Select the wildcard certificate you created in Step 3. Enable **Force SSL** and **HTTP/2 Support**.

---

## Security Best Practices

### 1. Make NGINX "Invisible"
By default, NGINX might show a welcome page if someone hits its IP directly. To prevent this:
*   Go to the **Settings** tab.
*   Change **Default Site** to **No Response (444)**. This immediately drops connections that don't specify a valid DNS name.

### 2. Restrict Access via Access Lists (ACLs)
If you expose NPM to the internet, you should restrict access to your internal management UIs.

1.  Go to the **Access Lists** tab and click **Add Access List**.
2.  **Name:** "Internal Only"
3.  **Satisfy Any:** Disabled (requires both Auth and IP if both are set).
4.  **Access Tab:** Add the following ranges to **Allow**:

| Name | IP Range | Description |
| :--- | :--- | :--- |
| **Local LAN** | `192.168.10.0/24` | Your physical home/office network. |
| **Headscale/VPN** | `100.64.0.0/10` | The secure Tailscale/Headscale IP range. |
| **Docker Internal** | `172.16.0.0/12` | Common Docker bridge network range. |

5.  **Important:** Any IP not explicitly allowed will be **Blocked**.
6.  Apply this "Internal Only" list to the **Proxy Host** settings for sensitive services.

### 3. Use Headscale for Remote Access
To access these "Internal Only" services from outside your home, use the Headscale VPN. This puts your device in the `100.64.0.0/10` range, granting you access through the ACL while keeping the service invisible to the rest of the internet.

*   See the [Headscale Network Setup](headscale-network-setup.md) for more details.

