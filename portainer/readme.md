# Portainer

This folder contains docker-compose files used to host [Portainer](https://portainer.io/) server and/or agent on Docker.

[Portainer](https://portainer.io/) is a management UI for Docker, like Docker Desktop but a web UI, that runs on your own server.

# Agent

If you have multiple docker servers you want to manage from Portainer, you can use the script in the **portainer-agent** folder portainer to install the agent in docker on the docker instances you want to manage.

## Synology

Under the folder **{prj-root}synology-nas/portainer** there is a script tuned for use on a Synology NAS.
