# Docker Service Ports

This document lists the default ports used by each service installed via Docker in this repository. Adjustments may be needed if you change the port mappings in your compose or run files.

| Service          | Container Port(s) | Host Port(s) | Description                                                        |
| ---------------- | ----------------- | ------------ | ------------------------------------------------------------------ |
| Headscale        | 8080, 9090        | 8080, 9090   | Headscale srv for "VPN" functionality & web UI & metrics           |
| Glance Dashboard | 8080              | 4403         | Glance, a dynamic dashboard                                        |
| Home Assistant   | 8123              | 8123         | Home Assistant for controlling local devices                       |
| Immich           | 2283, 3001        | 2283, 3001   | Immich srv for photo management (like Google photos)               |
| Nextcloud        | 80, 443           | 8081, 8443   | Nextcloud, similar to Google Drive                                 |
| Nginx Proxy      | 80, 443           | 80, 443      | Reverse proxy, for network routing                                 |
| Ollama           | 11434             | 11434        | Ollama API, for running local LLM's (AI)                           |
| Portainer        | 8000, 9000        | 8000, 9000   | Portainer, for controlling focker containers (Like Docker desktop) |
| Traccar          | 8082              | 4411         | Traccar, for geo-tracking of mobile devices                        |
| Vaultwarden      | 80                | 4410         | Vaultwarden password manager, like Bitwarden                       |
| Docmost          | 3000              | 4412         | Docmost, for documentation like a Wiki                             |
| SearXNG          | 8080              | 4522         | SearXNG, a privacy-respecting metasearch engine                    |
| Synapse          | 8008              | 4530         | Synapse, a Matrix homeserver for private messaging                 |
| Synapse Admin    | 80                | 4531         | Web UI for managing Synapse homeservers                            |
| Nextcloud AIO    | 8080              | 4504         | Nextcloud All-in-One admin interface                               |
| Verdaccio        | 4873              | 4873         | Verdaccio, local NPM registry                                      |
| Registry         | 5000              | 5000         | Local Docker registry                                              |
| Registry UI      | 80                | 6001         | Web UI for the local Docker registry                               |
| Linux in Docker  | 3000, 3001        | 3000, 3001   | webtop (Ubuntu XFCE) in Docker                                     |
| Watchtower       | N/A               | N/A          | Automation for Docker container images                              |
| ComfyUI         | 8188              | 4515         | ComfyUI, a powerful and modular stable diffusion GUI/backend        |

**Note:**

-  Host ports may be changed in your compose/run files. This table lists the defaults as set up by the provided scripts.
-  Some services may expose additional ports for internal or advanced features.
-  If you run multiple services on the same host, ensure port mappings do not conflict.
