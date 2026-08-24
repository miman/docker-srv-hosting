#!/bin/bash
set -e

# Ensure DOCKER_FOLDER is set
source ../../scripts/read-config.sh

# Ask if Watchtower should manage this service
ask_watchtower_label

# Create persistent data directories with correct ownership
mkdir -p "$DOCKER_FOLDER/open-notebook/surreal_data"
mkdir -p "$DOCKER_FOLDER/open-notebook/notebook_data"
chown -R 1000:1000 "$DOCKER_FOLDER/open-notebook/surreal_data"

# Create .env file if it doesn't exist
if [ -f .env ]; then
    echo ".env file already exists, skipping generation."
else
    echo "Creating .env file..."

    # Generate a random encryption key
    ENCRYPTION_KEY=$(openssl rand -hex 32 2>/dev/null || cat /proc/sys/kernel/random/uuid | tr -d '-' | head -c 40)
    SURREAL_PASSWORD=$(openssl rand -hex 16 2>/dev/null || cat /proc/sys/kernel/random/uuid | tr -d '-' | head -c 20)

    # Ask about Ollama connectivity
    echo ""
    echo "Open Notebook can connect to an Ollama instance for local AI models."
    echo "If you have Ollama running on this host, use: http://host.docker.internal:11434"
    echo "If using the Ollama container from this project, use: http://ollama:11434"
    read -p "Enter Ollama API base URL (leave empty to skip): " OLLAMA_URL

    cat > .env <<EOF
# Open Notebook Configuration
# Encryption key for credential storage (required)
ENCRYPTION_KEY=${ENCRYPTION_KEY}

# SurrealDB credentials
SURREAL_PASSWORD=${SURREAL_PASSWORD}

# Ollama connection (optional - configure if using local models)
# If Ollama runs on the host: http://host.docker.internal:11434
# If Ollama runs in a separate container on the same Docker network: http://ollama:11434
OLLAMA_API_BASE=${OLLAMA_URL}

# Add your AI provider API keys below as needed:
# OPENAI_API_KEY=
# GEMINI_API_KEY=
# ANTHROPIC_API_KEY=
# OPENROUTER_API_KEY=
EOF
    echo ".env file created."
fi

# Deploy
echo "Stopping existing containers..."
$COMPOSE_CMD down

echo "Pulling latest images..."
$COMPOSE_CMD pull

echo "Starting Open Notebook containers..."
$COMPOSE_CMD up -d

echo ""
echo "Open Notebook has been installed successfully!"
echo "- Web UI: http://localhost:4510"
echo "- API: http://localhost:4511"
echo ""
echo "On first login, you'll be prompted to set up the database (just click OK)."
echo "Then go to Manage → Models to configure your AI providers."
echo ""
