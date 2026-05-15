#!/bin/bash

# This script removes all created docker containers, networks & volumes
# OBS: This file will remove all volumes as well. 

echo "Running this will remove all Docker containers as well as all volumes created by this project"
read -p "Do you really want to delete all Docker containers & volumes? (y/N): " confirm

if [[ ! $confirm =~ ^[Yy]$ ]]; then
    echo "Aborting script."
    exit 1
fi

# Uninstall the home-assistant Docker container
if [ -d "cloud-services/home-assistant" ]; then
    echo "Cleaning up home-assistant..."
    pushd cloud-services/home-assistant > /dev/null
    if [ -f "cleanup-all.sh" ]; then
        bash cleanup-all.sh
    elif [ -f "cleanup-all.bat" ]; then
        echo "Warning: Only cleanup-all.bat found in cloud-services/home-assistant. Cannot run on Linux."
    fi
    popd > /dev/null
fi

# Uninstall the ollama Docker container
if [ -d "ai/ollama" ]; then
    echo "Cleaning up ollama..."
    pushd ai/ollama > /dev/null
    if [ -f "cleanup-all.sh" ]; then
        bash cleanup-all.sh
    elif [ -f "cleanup-all.bat" ]; then
        echo "Warning: Only cleanup-all.bat found in ai/ollama. Cannot run on Linux."
    fi
    popd > /dev/null
fi

# Uninstall the nextcloud Docker container
if [ -d "cloud-services/nextcloud" ]; then
    echo "Cleaning up nextcloud..."
    pushd cloud-services/nextcloud > /dev/null
    if [ -f "cleanup-all.sh" ]; then
        bash cleanup-all.sh
    elif [ -f "cleanup-all.bat" ]; then
        echo "Warning: Only cleanup-all.bat found in cloud-services/nextcloud. Cannot run on Linux."
    fi
    popd > /dev/null
fi

# Uninstall the nginx-reverse-proxy Docker container
if [ -d "infrastructure/nginx-reverse-proxy" ]; then
    echo "Cleaning up nginx-reverse-proxy..."
    pushd infrastructure/nginx-reverse-proxy > /dev/null
    if [ -f "cleanup-all.sh" ]; then
        bash cleanup-all.sh
    elif [ -f "cleanup-all.bat" ]; then
        echo "Warning: Only cleanup-all.bat found in infrastructure/nginx-reverse-proxy. Cannot run on Linux."
    fi
    popd > /dev/null
fi
