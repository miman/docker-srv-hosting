#!/bin/bash

# This script removes all created docker containers, networks & volumes

# Uninstall the ollama Docker container
docker compose down -v --rmi all

# Remove the volume used by the Ollama Docker containers
docker volume rm ollama 2>/dev/null || true
