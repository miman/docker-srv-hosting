# NetBird Client

[NetBird](https://netbird.io/) is an open-source zero-configuration VPN platform built on WireGuard® that lets you securely connect your devices over the internet.

This directory contains the configurations to deploy the **NetBird Client** on your server as a container. 

---

## 🚀 How to Get a Free NetBird Cloud Account & Setup Key

If you want to use NetBird's free managed cloud coordination server (which is free for up to 100 devices and perfect for most home servers), follow these steps to get started:

1. **Create an Account:**
   * Go to the NetBird web console: **[app.netbird.io](https://app.netbird.io/)**
   * Sign up using your Email, Google, GitHub, or Microsoft account.

2. **Generate a Setup Key:**
   * Once logged into the dashboard, navigate to the **Setup Keys** tab on the left sidebar.
   * Click the **Add Setup Key** button in the top right.
   * Give the key a friendly name (e.g., `Home Server Client`).
   * Keep the defaults (Reusable, Ephemeral disabled) and click **Create**.
   * **Copy the generated Setup Key** (it looks like a UUID, e.g., `XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX`). Keep it safe as you won't be able to see it again!

---

## 🛠️ Installation

The installer script will guide you through configuring your Setup Key and server Hostname automatically.

1. Run the main installer:
   ```bash
   ./install.sh
   ```
   *(Or run it directly from this directory if installing manually: `./infrastructure/netbird/client/install.sh`)*

2. When prompted:
   * Paste your **NetBird Setup Key** that you copied from the dashboard.
   * Confirm or enter a **Hostname** for this server (how it will show up in your NetBird console, e.g. `my-home-server`).

3. Once installed, go back to your **[NetBird Web Console](https://app.netbird.io/peers)** under the **Peers** tab. You will see your server online and connected!
