# Docmost Docker Setup

Docmost is an open-source, self-hosted documentation and knowledge management platform. This folder contains scripts to help you quickly deploy Docmost using Docker on Windows or Linux.

## Quick Start

### Windows

1. Run `install.bat`:
   -  Downloads the latest `docker-compose.yml` if not present.
   -  Changes the default web port from 3000 to 4412.
   -  Prompts you to edit the compose file for secrets and passwords.
   -  Starts the Docmost services with Docker Compose.

### Linux/macOS

1. Run `install.sh`:

   -  Downloads the latest `docker-compose.yml` if not present.
   -  Changes the default web port from 3000 to 4412.
   -  Prompts you to edit the compose file for secrets and passwords.
   -  Starts the Docmost services with Docker Compose.

2. Open and edit `docker-compose.yml`:
   -  Set `APP_URL` to your domain or `http://localhost:4412`.
   -  Set a strong `APP_SECRET` (32+ random characters).
   -  Replace `STRONG_DB_PASSWORD` in both `POSTGRES_PASSWORD` and `DATABASE_URL`.
3. Access Docmost at [http://localhost:4412](http://localhost:4412) after installation.

## Requirements

-  Docker and Docker Compose must be installed on your system.

## Resources

-  [Docmost Documentation](https://docmost.com/docs/installation)
-  [Docmost GitHub](https://github.com/docmost/docmost)

---

**Note:**

-  For production, set up a secure domain and use strong secrets/passwords.
-  You can upgrade Docmost by pulling the latest image and running `docker compose up -d` again.
