#!/bin/bash

# --- Lyra 2.0 Auto-Installer for RTX 5070 Ti ---

# 1. Configuration
REPO_URL="https://github.com/nv-tlabs/lyra.git"
INSTALL_DIR="Lyra-2.0"

echo "🚀 Starting Lyra 2.0 Installation..."

# 2. Check for NVIDIA Docker Runtime
if ! docker info | grep -q "Runtimes: nvidia"; then
    echo "❌ Error: NVIDIA Container Toolkit not found."
    echo "Please install it from: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html"
    exit 1
fi

# 3. Clone Repository
if [ ! -d "$INSTALL_DIR" ]; then
    echo "📂 Cloning Lyra 2.0 repository..."
    git clone $REPO_URL $INSTALL_DIR
else
    echo "📂 Directory $INSTALL_DIR already exists. Skipping clone."
fi

cd $INSTALL_DIR

# 4. Create local directories for persistence
echo "📁 Creating model and output directories..."
mkdir -p models
mkdir -p outputs

# 5. Generate optimized Docker Compose file
echo "📝 Generating optimized docker-compose.yml..."
cat <<EOF > docker-compose.yml
services:
  lyra-engine:
    build: .
    container_name: lyra_webui
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
    ports:
      - "7860:7860"
    environment:
      - LYRA_PRECISION=fp4
      - USE_FLASH_ATTENTION=1
    volumes:
      - ./models:/app/models
      - ./outputs:/app/outputs
    shm_size: '16gb'
    restart: unless-stopped
EOF

# 6. Build and Start
echo "🛠️ Building Lyra 2.0 Docker Image (this may take a while)..."
docker compose up --build -d

echo "------------------------------------------------"
echo "✅ Installation Complete!"
echo "🌐 Web UI: http://localhost:7860"
echo "📜 View Logs: docker logs -f lyra_webui"
echo "------------------------------------------------"
