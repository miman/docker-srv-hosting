#!/bin/bash

# Function to prompt for installation
prompt_install() {
  local name="$1"
  local dir="$2"
  local script="$3"  # Script to execute in the directory (e.g. ./install.sh)

  read -p "Do you want to install ${name} (y/N)? " answer
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    echo "Installing ${name} as a Docker container..."
    if cd "$dir"; then
      $script
      cd ..
    else
      echo "Failed to enter directory: ${dir}"
    fi
  else
    echo "Not installing ${name}"
  fi
}

prompt_install "Ollama" "ollama" "./install.sh"
prompt_install "Nextcloud" "nextcloud" "./install.sh"
prompt_install "nginx reverse-proxy" "nginx-reverse-proxy" "./install.sh"
prompt_install "Home Assistant" "home-assistant" "./install.sh"

