#!/bin/bash

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root (sudo su)" >&2
  exit 1
fi

read -p "Please enter the headscale URL (e.g., https:// headscale.example.com): " HEADSCALE_URL
if [ -z "$HEADSCALE_URL" ]; then
    echo "Error: HEADSCALE_URL is required." >&2
    exit 1
fi

export HEADSCALE_URL
echo "Using HEADSCALE_URL: $HEADSCALE_URL"

echo "Updating Linux environment..."
apt update -y
apt upgrade -y

echo "Installing Tailscale client..."
curl -fsSL https://tailscale.com/install.sh | sh

echo "Tailscale client installation complete."
echo "You can now start and configure Tailscale, e.g., 'sudo tailscale up'"

echo "Now connect to the headscale network."

tailscaled &
tailscale up --login-server ${HEADSCALE_URL}
tailscale list
echo "Tailscale client setup is complete."
