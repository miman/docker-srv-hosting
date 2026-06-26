# Uptime Kuma

This folder contains docker-compose files used to host [Uptime Kuma](https://uptimekuma.org/) on Docker.

[Uptime Kuma](https://uptimekuma.org/) is a web UI for monitoring services running on your own server.

## Notifications (Matrix)

Unlike some other services in this repository (like Watchtower), Uptime Kuma does not support configuring notification providers via environment variables. Instead, they must be configured manually through its Web UI.

If you have Matrix configured for notifications in this project, you can use those credentials to set up alerts in Uptime Kuma:

1. Locate your Matrix credentials in the `.env` file at the root of your project directory (look for `MATRIX_HOST`, `MATRIX_USER`, `MATRIX_PASS`, and `MATRIX_ROOM_ID`).
2. Log in to your Uptime Kuma dashboard (typically accessible at `http://localhost:4532`).
3. Click your profile icon in the top right corner and select **Settings**.
4. Navigate to the **Notifications** tab and click **Setup Notification**.
5. Set the **Notification Type** to **Matrix**.
6. Enter the details from your `.env` file into the corresponding fields.
7. Click **Test** to verify the connection, then **Save**.