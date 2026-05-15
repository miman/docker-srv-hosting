# DuckDNS Updater

[DuckDNS](https://www.duckdns.org/) is a free service that lets you use your own domain name with a dynamic IP address.  
This service updates your domain name with your current IP address.

This docker-compose.yml file installs [DuckDNS updater](https://github.com/linuxserver/docker-duckdns) on your local server.

## Installation

Run the installation script:

```bash
./install.sh
```

The script will automatically use the subdomain from your `base_dns_name` in `config.json` and prompt you for your DuckDNS token. For security, the token is not stored on disk.

