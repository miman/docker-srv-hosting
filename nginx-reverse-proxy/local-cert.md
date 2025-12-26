# Setup of local certificate for Nginx Reverse Proxy

In some cases you may not want to expose port 80 & 443 to be accessible from the internet to get a certificate.

If so then do the following steps to get you Nginx Proxy Manager to work with the4 DuckDns HTTPS certificate.

Here are the steps to use a DuckDns certificate using the token.

## Steps

### Prepare DNS name in DuckDns

1. Create an account or Login to DuckDns
2. Create a domain by entering you sub domain name and click "add domain" button (in this example we will use example.duckdns.org)
3. Add the IP address to your server
   * Local IP if you only want to access ti in your local network (or over a VPN)
   * External IP if you want to be able to access it from the outside

### Configure Nginx Proxy Manager

1. Click on the SSL certificates folder in Nginx Proxy Manager.
2. Click "Add SSL Certificate"
3. Enter your domain names (in this example: example.duckdns.org & \*.example.duckdns.org)
4. Add the email address for your duckdns account
5. activate "Use a DNS Challenge"
6. Choose DuckDns as DNS Provider
7. Copy the Token from your DuckDns page and replace the string "your-duckdns-token" in the "Credentials file content" box
8. Optionally set Propagation seconds to 120
9. Press Save
