## Notifications (Matrix)

Unlike some other services in this repository (like Watchtower), Uptime Kuma does not support configuring notification providers via environment variables. Instead, they must be configured manually through its Web UI.

If you have Matrix configured for notifications in this project, you can use those credentials to set up alerts in Uptime Kuma:

1. Locate your Matrix credentials in the `.env` file at the root of your project directory (look for `MATRIX_HOST`, `MATRIX_USER`, and `MATRIX_ROOM_ID`).
2. Log in to your Uptime Kuma dashboard (typically accessible at `http://localhost:4532`).
3. Click your profile icon in the top right corner and select **Settings**.
4. Navigate to the **Notifications** tab and click **Setup Notification**.
5. Set the **Notification Type** to **Matrix**.
6. Enter the details from your `.env` file (`MATRIX_HOST`, `MATRIX_USER`, `MATRIX_ROOM_ID`) along with your bot's **Access Token**.
7. Click **Test** to verify the connection, then **Save**.

### How to Create & Locate Matrix Credentials on a Synapse Server

If you are running your own Synapse Homeserver and managing it via an administrative panel (such as **Synapse Admin UI**), follow these steps to securely gather the properties needed for your configuration:

#### 1. `MATRIX_HOST`
* This is the base URL of your Matrix homeserver API client endpoint.
* **Format:** `https://matrix.yourdomain.com` (Ensure it includes `https://` and no trailing slashes).

#### 2. `MATRIX_USER`
For security best practices, **do not use your primary admin account**. Instead, create a dedicated bot user to stream notifications:
1. Open your **Synapse Admin UI**.
2. Navigate to the **Users** section and click **Create User** (or **Add User**).
3. Set a descriptive internal username (e.g., `uptime-kuma-bot`).
4. Generate a temporary password to create the account.
5. Save the user. 
   * `MATRIX_USER` will be the full Matrix ID format: `@uptime-kuma-bot:yourdomain.com`

#### 3. How to acquire the Matrix Access Token
Uptime Kuma authenticates directly using an ongoing session token. Choose one of the following methods to fetch the token for your bot user:

##### Method A: Via Synapse Admin UI
1. In **Synapse Admin UI**, go to the **Users** menu and click on your bot user.
2. Scroll down to the **Devices** or **Sessions** section.
3. If the bot has logged in at least once (e.g., via Element Web), you will see an active device listed.
4. Click on the device entry or look for an **Access Token** field to reveal and copy the token string (usually starts with `syt_`).

##### Method B: Via Terminal (Using `curl`)
You can force the Synapse homeserver to output an active access token directly over the API without a graphical client. Run this command on your server (replace with your domain and bot details):
```bash
curl -X POST "[https://matrix.yourdomain.com/_matrix/client/r0/login](https://matrix.yourdomain.com/_matrix/client/r0/login)" \
-d '{"type":"m.login.password", "user":"uptime-kuma-bot", "password":"YourBotPassword"}'