# ==============================================================================
# Whisper Voice Input - Local Speech-to-Text Transcription
# ==============================================================================
# OpenAI Whisper for local voice transcription (no cloud, privacy-first)
#
# Features:
#   - Local transcription (no API calls, no internet required)
#   - GPU acceleration (Vulkan) with CPU fallback
#   - Spanish default (auto-detect also available)
#   - Clone-first: same config on all machines
#   - Auto-detect hardware (GPU/CPU) at runtime
#
# Performance (aurin RTX 5080):
#   - ~0.14x real-time (2.6s to transcribe 18.5s audio)
#   - Encode time: ~22ms (GPU accelerated)
#
# Performance (macbook Intel CPU):
#   - ~4x real-time (~35s to transcribe 10s audio)
#   - Acceptable for occasional use
#
# Model: ggml-small.bin (466 MB, multilingual)
#   - Supports Spanish, English, and 97 other languages
#   - Excellent accuracy in Spanish
#   - Must be downloaded manually (see usage below)
#
# Usage:
#   1. Download model (first time only):
#      mkdir -p ~/.local/share/whisper/models
#      cd ~/.local/share/whisper/models
#      curl -L -O https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin
#
#   2. Record and transcribe:
#      whisper-brutal
#      (speak, press Ctrl+C when done)
#
# Pattern: Clone-First Pure
#   - No enable option (always active)
#   - No machine-specific config needed
#   - Scripts auto-detect hardware
#   - Same code works on all machines (aurin, macbook, vespino)
# ==============================================================================

{
  config,
  lib,
  pkgs,
  ...
}:

let
  dotfilesDir = "${config.home.homeDirectory}/dotfiles";
in
{
  # Always enabled (clone-first: no options needed)
  # Works on all machines with automatic hardware detection

  # Install Vulkan version (supports both GPU and CPU fallback)
  # whisper-cpp-vulkan auto-detects: uses Vulkan if GPU available, CPU if not
  home.packages = with pkgs; [
    whisper-cpp-vulkan # GPU Vulkan backend (NVIDIA/AMD) with CPU fallback
    ffmpeg-full # Audio recording (already in passh.nix but explicit here)
    pulseaudio # Provides pactl for audio device detection
  ];

  # Symlink scripts to ~/.local/bin/
  # Using mkOutOfStoreSymlink for mutable, editable scripts
  home.file = {
    ".local/bin/whisper-brutal".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/scripts/whisper-brutal";
  };
}
