# Docker Service Ports

This document lists the default ports used by each service installed via Docker in this repository. Adjustments may be needed if you change the port mappings in your compose or run files.

| Service          | Container Port(s) | Host Port(s) | Description                   |
| ---------------- | ----------------- | ------------ | ----------------------------- |
| Headscale        | 8080, 9090        | 8080, 9090   | Headscale web UI & metrics    |
| Glance Dashboard | 8080              | 4403         | Glance web dashboard          |
| Home Assistant   | 8123              | 8123         | Home Assistant web UI         |
| Immich           | 2283, 3001        | 2283, 3001   | Immich web & API              |
| Nextcloud        | 80, 443           | 8081, 8443   | Nextcloud web UI              |
| Nginx Proxy      | 80, 443           | 80, 443      | Reverse proxy                 |
| Ollama           | 11434             | 11434        | Ollama API                    |
| Portainer        | 8000, 9000        | 8000, 9000   | Portainer web UI & Edge Agent |
| Traccar          | 8082              | 4411         | Traccar web UI                |
| Vaultwarden      | 80                | 4410         | Vaultwarden web UI            |

**Note:**

-  Host ports may be changed in your compose/run files. This table lists the defaults as set up by the provided scripts.
-  Some services may expose additional ports for internal or advanced features.
-  If you run multiple services on the same host, ensure port mappings do not conflict.
