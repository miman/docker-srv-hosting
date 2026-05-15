#!/bin/bash

# This script removes all created docker containers, networks & volumes

# Uninstall the Docker container
docker compose down -v --rmi all

# Remove the volumes used by the Docker container
docker volume rm nextcloud_nextcloud_db 2>/dev/null || true
docker volume rm nextcloud_nextcloud_data 2>/dev/null || true
docker volume rm nextcloud_redis_data 2>/dev/null || true
