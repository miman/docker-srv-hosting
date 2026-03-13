# Matrix Synapse - Home Server

Synapse is the reference implementation of a Matrix homeserver. It allows you to host your own decentralized, private secure communication platform.

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
