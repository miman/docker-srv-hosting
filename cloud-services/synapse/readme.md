# Matrix Synapse - Home Server

[Synapse](https://matrix.org/docs/projects/server/synapse) is the reference implementation of a Matrix homeserver. It allows you to host your own decentralized, private secure communication platform.

It is used for chatting, sending files, and voice and video calls, similar to Signal, Telegram, WhatsApp, or Discord, but it is decentralized and open source.

It is the server behind [Element](https://element.io/), which is the recommended client to use with Synapse. You can of course use other Matrix clients as well.

[Matrix](https://matrix.org/) is a decentralized, open standard for instant messaging, file sharing, voice and video calls. It is designed to be secure and private, and it allows you to host your own homeserver, which means you have full control over your data. Unlike centralized messaging apps like WhatsApp, Telegram, Signal, or Discord, Matrix allows users to choose their own server and client, and to control their own data and privacy.

## Installation & Running

To deploy Synapse, you can use the provided installation script:

```bash
./install.sh
```

### Configuration Generation

The first time you run the installer, it will generate a `homeserver.yaml` file using your `BASE_DNS_NAME`. 

By default, Synapse uses **SQLite** as its database, which is stored in the data folder. This is sufficient for small personal homeservers.

### Running directly

```bash
docker compose up -d
```

Once running, Synapse will be accessible at: `http://localhost:4530`
Synapse Admin will be accessible at: `http://localhost:4531`

### First-Time Setup & Usage

#### 1. Creating an Admin User

By default, registration via the client is closed for security. You need to create your first administrative user via the command line. Run the following command in your terminal while the containers are running:

```bash
podman-compose exec synapse register_new_matrix_user -c /data/homeserver.yaml http://localhost:8008
```

If you use Docker, change `podman-compose` to `docker compose` in the command above.

Follow the interactive prompts:

    Username: Choose your desired username (e.g., admin).

    Password: Choose a secure password.

    Make admin? Type yes.

    Note on Initial Credentials: There are no default pre-configured usernames or passwords. You must create your own account using the step above before you can log in.

#### 2. Logging In via Element Client

Once your user is created, open your Element client (or go to https://app.element.io if using the web version) and configure your connection:

    On the login screen, click Edit next to the default "Homeserver" field (which defaults to matrix.org).

    Select Other Homeserver.

    In the Homeserver URL field, enter your server's address:

        Local testing: http://localhost:4530 (or http://YOUR_SERVER_IP:4530)

        Production: https://matrix.yourdomain.com (if you have set up the reverse proxy)

    Enter the Username and Password you created in Step 1.

    Click Sign In.
---

## Reverse Proxy Integration

If you are using the Nginx Reverse Proxy included in this project, you should add a configuration to route your Matrix traffic (usually `https://matrix.yourdomain.com`) to `http://synapse:8008`.

## Client

### Element Web (Self-Hosted)

During installation, you can choose to deploy a self-hosted Element Web client alongside Synapse. This gives you a full web UI at `http://localhost:4532` that is pre-configured to connect to your Synapse instance.

The configuration is stored at `$DOCKER_FOLDER/synapse/element-web/config.json`. You can edit this file to customize the client (e.g., update the homeserver URL for production use behind a reverse proxy).

### Desktop & Mobile Clients

Clients can be downloaded here:
https://element.io/sv/download
