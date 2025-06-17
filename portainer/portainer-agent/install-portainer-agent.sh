# Docker run command to install the Portainer Agent
#
# This command deploys the Portainer Agent container, making the Docker environment
# it runs on manageable by a central Portainer Server instance.

docker run -d \
  -p 9001:9001 \
  --name portainer_agent \
  --restart always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /var/lib/docker/volumes:/var/lib/docker/volumes \
  portainer/agent
  