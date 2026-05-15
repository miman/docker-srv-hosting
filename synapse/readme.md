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

---

## Reverse Proxy Integration

If you are using the Nginx Reverse Proxy included in this project, you should add a configuration to route your Matrix traffic (usually `https://matrix.yourdomain.com`) to `http://synapse:8008`.

## Client

Clients can be downloaded here:
https://element.io/sv/download
