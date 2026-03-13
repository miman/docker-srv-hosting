# Use the proven stable 22.04 base with CUDA 13.0 support for Blackwell (sm_120)
FROM nvidia/cuda:13.0.1-cudnn-runtime-ubuntu22.04

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    python3-pip \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Clone ComfyUI repository
RUN git clone https://github.com/comfyanonymous/ComfyUI.git .

# THIS IS THE CRITICAL LINE FOR THE 5070 Ti (Blackwell)
# Install PyTorch built specifically for CUDA 13.0
RUN pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu130

# Install ComfyUI dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Install Manager + its specific requirements
RUN git clone https://github.com/ltdrdata/ComfyUI-Manager.git custom_nodes/ComfyUI-Manager
RUN pip install --no-cache-dir comfyui-manager
RUN pip install --no-cache-dir -r custom_nodes/ComfyUI-Manager/requirements.txt

# Clone and install GGUF support for ComfyUI
RUN git clone https://github.com/city96/ComfyUI-GGUF.git custom_nodes/ComfyUI-GGUF && \
    pip install --no-cache-dir gguf

# Pre-configure ComfyUI-Manager to allow it to run in "listen" mode (security_level = weak)
RUN mkdir -p /app/user/__manager && \
    printf "[comfy_manager]\nsecurity_level = weak\nnetwork_mode = personal_cloud\n" > /app/user/__manager/config.ini

# Save a copy of the built-in custom nodes and config so we can restore them if the bind volume is empty
RUN cp -r custom_nodes custom_nodes_init && \
    cp -r user user_init

# Expose the port used by ComfyUI
EXPOSE 8188

# Restore built-in nodes and config to the volume at launch, then run ComfyUI
CMD ["/bin/sh", "-c", "cp -rn /app/custom_nodes_init/* /app/custom_nodes/ 2>/dev/null || true && cp -rn /app/user_init/* /app/user/ 2>/dev/null || true && python3 main.py --listen 0.0.0.0 --enable-manager --enable-manager-legacy-ui --user-directory /app/user"]
