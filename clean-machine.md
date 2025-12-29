# Clean machien requirements

create a shell script "install-clean.sh" that goes from a clean ubuntu srv to have this installed:

* docker
* tailscale client
 
# Installed in docker

* Nginx Proxy manager
  * install script: nginx-reverse-proxy/install.sh
* headscale
  * install script: headscale/install.sh
* portainer agent
  * install script: portainer/portainer-agent/install-portainer-agent.sh

# Configuration

The script should ask for the docker config root and store this in the user home folder in a folder called .hsc and in that folder a file called config.json

This home folder should be used as root for all docker compose files volumes blocks.
So for example:
if the user selects $HOME/docker_stacks as root folder
And we install nginx that has

      volumes:
         - {ROOT_FOLDER}/nginx-pm:/data
         - {ROOT_FOLDER}/nginx-pm:/etc/letsencrypt

all its volume data would be under ~/docker_stacks/nginx-pm

If the config file already exist, the root folder in that file should be used as default for when installing new services

# Pre work

* ensure the os is up to date (apt update & upgrade...) before installing everything
