#!/bin/bash

# ==============================================================================
# WHAT THIS SCRIPT DOES:
# This script automates the creation of a customized Ollama LLM inside a Docker
# container using a local 'Modelfile'. It takes the desired new model name as
# a mandatory argument, copies the Modelfile into the container, builds the
# model, and cleans up the temporary file afterwards.
#
# WHY WE DO IT THIS WAY:
# 1. Ollama Parser Limitations: Streaming a Modelfile via stdin ('-f -') causes 
#    Ollama's builder to fail when referencing existing images with complex tags 
#    or Hugging Face URLs (throwing "no Modelfile or safetensors files found"). 
#    Ollama expects a physical file on a disk path to resolve local components.
# 2. The Copy & Build Solution ('docker cp'): To bypass this limitation, we 
#    securely copy the Modelfile into the container's '/tmp' directory first. 
#    This gives Ollama an absolute disk path ('/tmp/Modelfile.tmp') inside its 
#    own environment, allowing it to instantly match your cached local layers.
# ==============================================================================

# ==========================================
# CONFIGURATION & ARGUMENTS
# ==========================================
CONTAINER_NAME="ollama"                     # Name of your running Ollama Docker container
MODELFILE_NAME="Modelfile"                  # Name of the target Modelfile in the current directory
NEW_MODEL_NAME=$1                           # Captures the first argument passed to the script

# Check if the mandatory model name argument was provided
if [ -z "$NEW_MODEL_NAME" ]; then
    echo "❌ Error: You must provide a name for the new model as an argument!"
    echo "💡 Usage: $0 <new-model-name>"
    echo "   Example:  $0 gemma4-12-agent"
    exit 1
fi

# ==========================================
# VALIDATION & BUILD
# ==========================================

# 1. Verify that the Modelfile exists in the current working directory
if [ ! -f "$MODELFILE_NAME" ]; then
    echo "❌ Error: Could not find '$MODELFILE_NAME' in the current directory ($PWD)."
    exit 1
fi

# 2. Verify that the Ollama container is actually running
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "❌ Error: The Docker container '$CONTAINER_NAME' is not running."
    exit 1
fi

echo "🚀 Step 1: Copying Modelfile into the container..."
# Copy the local host file into the container's temporary directory
docker cp "$MODELFILE_NAME" "${CONTAINER_NAME}:/tmp/Modelfile.tmp"

echo "🐳 Step 2: Building '${NEW_MODEL_NAME}' inside container..."
# Run the create command using the absolute path to the file inside the container
docker exec -it "$CONTAINER_NAME" ollama create "$NEW_MODEL_NAME" -f /tmp/Modelfile.tmp

echo "🧹 Step 3: Cleaning up container filesystem..."
# Remove the temporary file from the container to prevent clutter
docker exec "$CONTAINER_NAME" rm /tmp/Modelfile.tmp

# 4. Verify the final result
echo "📊 Fetching updated list of installed models..."
docker exec -it "$CONTAINER_NAME" ollama list

echo "✅ Done!"