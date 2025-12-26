# Secure network setup

## Services needed

* NGINX Proxy Manager
* Headscale server

## Port forwarding
* Port 443: TCP -> NGINX server
* Port 41641: UDP -> Headscale server

## NGINX Setup

### Ensure server is invisible for all clients besides yourself

* Default Site: In NPM Settings, set the Default Site to "444 No Response".
  * This drops connections from bots or scanners that do not use your specific DuckDNS hostname.
* Global Hardening: In the Advanced tab of your Proxy Hosts, add server_tokens off; to hide the Nginx version from attackers.
* Access List: Create a list named "VPN & Local Access":
* Allow: 192.168.68.0/24 (Home LAN).
* Allow: 100.64.0.0/10 (Headscale/Tailscale network).
* Deny: All (Blocks everyone else).

### Headscale server must be accessible from the internet

* Proxy Host: headscale.mydomain.duckdns.org.
* Forward IP: 192.168.68.121 | Port: 45450 (or your mapped 8080).
* Access List: Set to "Public" or "None".
* Note: Your phone must be able to reach Headscale via the public internet to authenticate before the VPN tunnel is established.
* Websockets Support: Must be ON for Headscale communication.

### No other servers should be accessible from the internet, only LAN & Headscale network

* For every other service (Home Assistant, Nextcloud, etc.), apply the "VPN & Local Access" Access List to their respective Proxy Hosts.
* This ensures that even if someone knows your domain name, they cannot see the login page unless they are connected to your Headscale VPN.

## Traffic Flow Summary
* Handshake: Client connects to RPI via TCP 443 to reach the Headscale control plane.
* Tunneling: Once authenticated, the client and NAS establish a direct encrypted tunnel.
* Data: All subsequent service traffic (e.g., Service X) is encapsulated in WireGuard packets and sent directly to the NAS via UDP 41641.
* Internal Delivery: The internal NPM on the NAS terminates the HTTPS layer and forwards the request to the specific Docker container.