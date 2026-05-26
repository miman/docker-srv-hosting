#!/bin/bash
# filepath: /c:/code/mt/docker-local-ai/ollama/install.sh
set -e

# Ensure DOCKER_FOLDER is set
source ../../scripts/read-config.sh

# Ask if Watchtower should manage this service
ask_watchtower_label

# Ensure the docker network "local-ai-network" exists
if ! $CONTAINER_CMD network ls --filter name=local-ai-network --format '{{.Name}}' | grep -q "^local-ai-network$"; then
  $CONTAINER_CMD network create local-ai-network
else
  echo "The network local-ai-network already exists."
fi

# Ensure data directory exists
mkdir -p "$DOCKER_FOLDER/ollama"

# Prompt for Nvidia GPU usage
read -p "Do you have an Nvidia GPU you want to use with Ollama (y/N)?  " answerNvidia
echo "Deploying container..."
if [[ "$answerNvidia" =~ [Yy]$ ]]; then
  echo "Using Nvidia card in Ollama"

  # Check that nvidia-smi is available (driver installed)
  if ! command -v nvidia-smi &> /dev/null; then
    echo "Error: nvidia-smi not found. Please install the NVIDIA driver first." >&2
    exit 1
  fi
  echo "  -> NVIDIA driver detected: $(nvidia-smi --query-gpu=driver_version --format=csv,noheader | head -1)"

  # Detect if running on Windows (Git Bash / MSYS / WSL host)
  IS_WINDOWS=false
  if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
    IS_WINDOWS=true
  elif [[ "$(uname -s)" == MINGW* || "$(uname -s)" == MSYS* ]]; then
    IS_WINDOWS=true
  fi

  if [ "$IS_WINDOWS" = true ]; then
    # On Windows, Docker Desktop handles GPU passthrough via WSL2 natively.
    # No nvidia-container-toolkit or CDI setup needed.
    echo "  -> Windows detected. Docker Desktop handles GPU passthrough via WSL2."
    echo "  -> Ensure Docker Desktop has WSL2 backend enabled (Settings > General > Use WSL2)."
  else
    # Linux: check that nvidia-container-toolkit is installed
    if ! command -v nvidia-ctk &> /dev/null; then
      echo "nvidia-container-toolkit is not installed."
      read -p "Do you want to install it now? (y/N): " install_ctk
      if [[ "$install_ctk" =~ [Yy]$ ]]; then
        echo "Installing nvidia-container-toolkit..."
        if command -v apt-get &> /dev/null; then
          # Debian/Ubuntu
          curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
          curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
            sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
            sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
          sudo apt-get update
          sudo apt-get install -y nvidia-container-toolkit
        elif command -v dnf &> /dev/null; then
          # Fedora/RHEL
          curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo | \
            sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo
          sudo dnf install -y nvidia-container-toolkit
        elif command -v pacman &> /dev/null; then
          # Arch/Manjaro
          sudo pacman -S --noconfirm nvidia-container-toolkit
        else
          echo "Error: Could not detect package manager (apt/dnf/pacman). Please install nvidia-container-toolkit manually." >&2
          echo "  See: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html"
          exit 1
        fi
      else
        echo "Error: nvidia-container-toolkit is required for GPU support." >&2
        exit 1
      fi
    fi

    # For Podman: ensure CDI is configured
    if [ "$CONTAINER_ENGINE" == "podman" ]; then
      echo "  -> Podman detected, checking CDI (Container Device Interface) configuration..."
      CDI_SPEC="/etc/cdi/nvidia.yaml"
      if [ ! -f "$CDI_SPEC" ]; then
        echo "  -> CDI spec not found at $CDI_SPEC. Generating..."
        sudo nvidia-ctk cdi generate --output="$CDI_SPEC"
        echo "  -> CDI spec generated successfully."
      else
        echo "  -> CDI spec already exists at $CDI_SPEC."
      fi
      # Verify CDI devices are listed
      echo "  -> Available CDI devices:"
      nvidia-ctk cdi list 2>/dev/null | head -5
    else
      # For Docker: configure the nvidia runtime
      echo "  -> Docker detected, configuring nvidia runtime..."
      sudo nvidia-ctk runtime configure --runtime=docker 2>/dev/null || true
      sudo systemctl restart docker 2>/dev/null || true
    fi
  fi

  if [ "$CONTAINER_ENGINE" == "podman" ]; then
    COMPOSE_PART="-f docker-compose.yaml -f docker-compose-nvidia-podman.yaml"
  else
    COMPOSE_PART="-f docker-compose.yaml -f docker-compose-nvidia.yaml"
  fi
else
  COMPOSE_PART="-f docker-compose.yaml"
fi

# Include override if it exists
if [ -f "docker-compose.override.yml" ]; then
  COMPOSE_PART="$COMPOSE_PART -f docker-compose.override.yml"
elif [ -f "docker-compose.override.yaml" ]; then
  COMPOSE_PART="$COMPOSE_PART -f docker-compose.override.yaml"
fi
# echo "COMPOSE_PART = $COMPOSE_PART"

$COMPOSE_CMD down
$COMPOSE_CMD pull ollama-container
$COMPOSE_CMD $COMPOSE_PART up -d --force-recreate --build ollama-container

echo "Ollama has been installed and is accessible on http://localhost:11434"
echo "Find and download models here: https://ollama.com/library"

read -p "Do you want to install an ollama alias in your rc file so it maps to your docker ollama instance (y/N)? " answer_alias
if [[ "$answer_alias" =~ [Yy]$ ]]; then
  echo "Added ollama alias..."
  ./add-ollama-alias.sh
fi

# Prompt for pulling the models
read -p "Do you want to install granite3.1-dense:2b model into Ollama (y/N)? " answer_model
if [[ "$answer_model" =~ [Yy]$ ]]; then
  echo "Installing granite3.1-dense:2b as a model in Ollama..."
  $CONTAINER_CMD exec -it ollama ollama pull granite3.1-dense:2b
fi

read -p "Do you want to be able to use image as input and install llava-phi3 model into Ollama (y/N)? " answer_model
if [[ "$answer_model" =~ [Yy]$ ]]; then
  echo "Installing llava-phi3 as a model in Ollama..."
  $CONTAINER_CMD exec -it ollama ollama pull llava-phi3
fi
