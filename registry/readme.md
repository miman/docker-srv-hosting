# Registry

[registry-ui](https://github.com/joxit/docker-registry-ui) is a web interface for your private Docker registry. It allows you to view, search, and delete Docker images stored in your registry.

It is used to store and serve Docker images for your private use, it caches images from the internet when you pull them for the first time. 

Then when you deploy it on another machine, it will serve the images from the local cache instead of downloading them from the internet.

Example scenario:
1. You are on main server and pull a lot of images from Docker Hub. 
2. Then you want to deploy the same stack on a second server that has no internet connection. 
3. You can then use this registry on the main server to serve the images to the second server.

## Installation

1. **Navigate to the registry directory:**
   ```bash
   cd ~/docker_stacks/registry
   ```

2. **Run the installer:**
   ```bash
   ./install.sh
   ```

3. **Follow the on-screen prompts:**
   - Select the registry version
   - Configure network settings

