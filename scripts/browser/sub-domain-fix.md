How to Enable Subdomain-Specific Logins in Firefox

If you are hosting multiple services using a dynamic DNS provider (like DuckDNS) and notice that Firefox groups all your passwords under the main domain (e.g., `mysrv.duckdns.org`) instead of separating them for each subdomain (`immich.mysrv.duckdns.org` vs `nginx.mysrv.duckdns.org`), you can fix this by changing a hidden configuration setting in Firefox.

This issue occurs because Firefox, by default, groups credentials based on the base domain rather than the full subdomained URL. 

Follow these steps to force Firefox to treat each subdomain as a completely separate site.

---

## Step-by-Step Guide

### 1. Open Advanced Configuration
Open a new tab in Firefox, type the following into the address bar, and press **Enter**.

```text
about:config
```

### 2. Accept the Warning
You will see a warning screen saying *"Proceed with Caution"*. Click **Accept the Risk and Continue**.

### 3. Search for the Match Setting
In the search box at the top of the page, type or copy-paste the following preference name:
```text
signon.orgOriginMatch
```

### 4. Toggle the Value to True

By default, this setting is set to false.

Click the Toggle button (the two-way arrow icon on the far right) or double-click the row to change its value to **true**.

What Happens Next?

Strict Separation: Firefox will now look at the exact subdomain, protocol (HTTP vs HTTPS), and port when suggesting or saving credentials.

Existing Passwords: You may need to update or re-save your credentials once for each specific subdomain so Firefox maps them correctly under the new rule.