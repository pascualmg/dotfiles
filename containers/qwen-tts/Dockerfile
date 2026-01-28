# Qwen TTS Voice Cloning - Docker with CUDA support
# RTX 5080 (Blackwell sm_120) requires CUDA 13+ and PyTorch nightly
FROM nvidia/cuda:13.1.1-cudnn-devel-ubuntu22.04

# Avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Madrid

# Install Python and system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    ffmpeg \
    sox \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install PyTorch nightly with CUDA 13.0 (sm_120 support for Blackwell/RTX 50xx)
# Solo torch - sin torchvision/torchaudio para evitar backtracking de pip
RUN pip3 install --no-cache-dir --pre torch \
    --index-url https://download.pytorch.org/whl/nightly/cu130

# Install TTS packages (numpy first - required by sox dependency)
RUN pip3 install --no-cache-dir numpy && \
    pip3 install --no-cache-dir \
    qwen-tts \
    transformers \
    soundfile \
    librosa

# CRITICAL: Reinstall PyTorch + torchaudio nightly cu130 AFTER qwen-tts
# qwen-tts installs torch/torchaudio stable with CUDA 12.8 which doesn't support RTX 5080 (sm_120)
RUN pip3 install --no-cache-dir --pre torch torchaudio --force-reinstall \
    --index-url https://download.pytorch.org/whl/nightly/cu130

# Create directories
RUN mkdir -p /voice-cloning/references /voice-cloning/output

WORKDIR /app

# Entry point will be the script
ENTRYPOINT ["python3", "/app/qwen-tts-clone"]
