# Immich Self-Hosted Photo & Video Backup

Immich is an open-source, self-hosted solution for backing up and managing your photos and videos. It provides features similar to Google Photos, but runs entirely on your own server for privacy and control.

## Features

-  Automatic photo and video backup from mobile devices
-  Albums, sharing, and search
-  Modern web and mobile clients
-  Runs on Docker for easy deployment

## Quick Start

1. Edit the `docker-compose.yml` file to adjust ports, volumes, and other settings as needed.
2. Run `install.bat` (Windows) or `install.sh` (Linux/macOS) to deploy Immich using Docker Compose.
3. Access Immich at [http://localhost:2283](http://localhost:2283) (or the port you configured).

## Data Storage

-  All photos, videos, and metadata are stored in the volume you map to the container in `docker-compose.yml`.

## Documentation & Resources

-  [Immich GitHub](https://github.com/immich-app/immich)
-  [Immich Documentation](https://immich.app/docs/)

---

**Note:**

-  Make sure Docker and Docker Compose are installed on your system.
-  For production use, consider setting up backups and using a reverse proxy with HTTPS.
