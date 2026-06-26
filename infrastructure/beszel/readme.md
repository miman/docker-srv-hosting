# Beszel

This folder contains docker-compose files used to host [Beszel](https://beszel.dev/) on Docker or Podman.

[Beszel](https://beszel.dev/) is a web UI for monitoring services running on your own server.

## Post-Installation Setup (KEY and TOKEN)

Beszel uses a cryptographic `KEY` and `TOKEN` to secure communication between the Hub and the Agent. You generate these from the web UI after your initial deployment.

1. **Start the containers** using the `docker-compose.yml` with the `<token>` and `"<key>"` placeholders left exactly as they are. The Hub will start, but the Agent won't connect yet.
2. **Create your account** by opening the Beszel Web UI in your browser (e.g., `http://localhost:4533` or your server's IP/domain).
3. **Generate the credentials**:
   - Once logged in, click the **Add System** button in the top right corner of the dashboard.
   - Give your system a name (like "Local Server").
   - The popup dialog will show a block of `docker-compose` code containing a unique `KEY` and `TOKEN`.
4. **Update your compose file**: Copy the real `KEY` and `TOKEN` from the UI and paste them into your `docker-compose.yml` file, replacing the `<key>` and `<token>` placeholders. (Keep the quotes around the `KEY`).
5. **Restart the Agent**: Restart your compose stack (e.g., run `./install.sh` again or `docker compose up -d`). The Agent will instantly read the new credentials, authenticate, and your dashboard will start showing live stats.

## Synology

Under the folder **{prj-root}synology-nas/beszel** there is a script tuned for use on a Synology NAS.

