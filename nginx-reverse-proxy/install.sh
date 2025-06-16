#!/bin/bash

# Run the Docker compose file
docker compose down
docker compose pull
docker compose up -d

echo "reverse-proxy has been installed and is accessible on http://localhost:8123"
echo "log in with the following username and password: Default username: admin@example.com. Default password: changeme"
echo "See here for how to configure it: https://www.youtube.com/watch?v=qlcVx-k-02E""