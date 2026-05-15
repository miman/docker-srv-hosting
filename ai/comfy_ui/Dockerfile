# Use the proven stable 22.04 base with CUDA 13.0 support
FROM nvidia/cuda:13.0.1-cudnn-runtime-ubuntu22.04

# Set environment variables to force the correct library usage
ENV LD_LIBRARY_PATH=/usr/local/lib/python3.10/dist-packages/nvidia/cublas/lib:/usr/local/cuda/lib64:$LD_LIBRARY_PATH
ENV PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y \
    git python3-pip libgl1-mesa-glx libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
RUN git clone https://github.com/comfyanonymous/ComfyUI.git .

# FIX: Use --extra-index-url and force the Blackwell-compatible version (2.12+)
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu130

RUN pip install --no-cache-dir -r requirements.txt

# Install Manager + GGUF Support
RUN git clone https://github.com/ltdrdata/ComfyUI-Manager.git custom_nodes/ComfyUI-Manager && \
    pip install --no-cache-dir -r custom_nodes/ComfyUI-Manager/requirements.txt
RUN git clone https://github.com/city96/ComfyUI-GGUF.git custom_nodes/ComfyUI-GGUF && \
    pip install --no-cache-dir gguf

# Rest of your setup...
RUN mkdir -p /app/user/__manager /app/user/default /app/templates
RUN cp -r custom_nodes custom_nodes_init && cp -r user user_init && cp -r templates templates_init

EXPOSE 8188

# ADDED: This ensures the library path is set every time the container starts
CMD ["/bin/sh", "-c", "export LD_LIBRARY_PATH=/usr/local/lib/python3.10/dist-packages/nvidia/cublas/lib:$LD_LIBRARY_PATH && cp -rn /app/custom_nodes_init/* /app/custom_nodes/ 2>/dev/null || true && cp -rn /app/user_init/* /app/user/ 2>/dev/null || true && cp -rn /app/templates_init/* /app/templates/ 2>/dev/null || true && python3 main.py --listen 0.0.0.0 --user-directory /app/user"]
