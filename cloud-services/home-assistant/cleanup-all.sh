#!/bin/bash

# This script removes all created docker containers, networks & volumes

# Uninstall the Docker container
docker compose down -v --rmi all

# Remove the volume used by the Docker container
docker volume rm home-assistant_home-assistant 2>/dev/null || true
