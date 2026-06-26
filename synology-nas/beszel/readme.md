# Beszel

This folder contains docker-compose files used to host [Beszel](https://beszel.dev/) on Docker on a  Synology NAS.

[Beszel](https://beszel.dev/) is a web UI for monitoring services running on your own server.

- Re-create the folders: Docker on Synology will automatically create missing folders, but it will create them with root ownership. It's usually best practice to manually create the beszel, beszel/data, beszel/socket, and beszel/agent_data folders via Synology's File Station before running the compose file so your user owns them.
- APP_URL: If you plan to set up notifications or OAuth, you might want to change APP_URL: http://localhost:4533 to your actual NAS IP address (e.g., APP_URL: http://192.168.1.100:4533) so that generated links in notifications point to the right place.

## Post-Installation Setup (KEY and TOKEN)

Beszel uses a cryptographic `KEY` and `TOKEN` to secure communication between the Hub and the Agent. You generate these from the web UI after your initial deployment.

1. **Start the containers** using the `docker-compose.yml` with the `<token>` and `"<key>"` placeholders left exactly as they are. The Hub will start, but the Agent won't connect yet.
2. **Create your account** by opening the Beszel Web UI in your browser (e.g., `http://<YOUR_NAS_IP>:4533`).
3. **Generate the credentials**:
   - Once logged in, click the **Add System** button in the top right corner of the dashboard.
   - Give your system a name (like "Synology NAS").
   - The popup dialog will show a block of `docker-compose` code containing a unique `KEY` and `TOKEN`.
4. **Update your compose file**: Copy the real `KEY` and `TOKEN` from the UI and paste them into your `docker-compose.yml` file, replacing the `<key>` and `<token>` placeholders. (Keep the quotes around the `KEY`).
5. **Restart the Agent**: Restart your compose stack (using Container Manager or `docker compose up -d`). The Agent will instantly read the new credentials, authenticate, and your dashboard will start showing live stats.