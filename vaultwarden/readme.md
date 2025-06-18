# Vaultwarden Docker Setup

Vaultwarden is an open-source, lightweight alternative to Bitwarden server, providing secure password management and self-hosting capabilities.

You can use official Bitwarden clients (web, desktop, mobile, browser extensions) to connect to your Vaultwarden instance just like you would with the official Bitwarden service.

This prj will install a Vaultwarden server as a Docker container

## Quick Start

### Windows

1. Run `install.bat`.
2. When prompted, enter the absolute path to the folder where Vaultwarden should store its data.
3. Optionally, enter your domain (e.g., `https://vw.domain.tld`) or leave blank for local use. Set this if you are behind a reverse proxy
4. The script will pull the latest Vaultwarden image and start the container on port 4410.
5. Access Vaultwarden at [http://localhost:4410](http://localhost:4410).

### Linux/macOS

1. Run `install.sh`.
2. Follow the same prompts as above.
3. The script will pull the latest Vaultwarden image and start the container on port 4410.
4. Access Vaultwarden at [http://localhost:4410](http://localhost:4410).

## Notes

-  The data directory you provide will be mounted to `/data` in the container. This is where Vaultwarden stores all persistent data.
-  If you provide a domain, it will be set as the `DOMAIN` environment variable for Vaultwarden (recommended for reverse proxy/production setups).
-  If you leave the domain blank, Vaultwarden will use default settings suitable for local testing.
-  Make sure Docker is installed and running on your system.

## Resources

-  [Vaultwarden GitHub](https://github.com/dani-garcia/vaultwarden)
-  [Vaultwarden Documentation](https://github.com/dani-garcia/vaultwarden/wiki)
