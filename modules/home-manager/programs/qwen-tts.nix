# =============================================================================
# Qwen3-TTS - Voice Cloning / Text-to-Speech
# =============================================================================
# Clone-first: Voice cloning script available on all machines
#
# FEATURES:
#   - Voice cloning (3-15s reference audio → clone voice)
#   - Text-to-Speech with custom voice
#   - Multi-language support (Spanish, English, Chinese, etc.)
#   - Local inference on GPU (RTX 5080)
#
# MODEL:
#   - Qwen3-TTS-12Hz-1.7B-Base (~3.5GB)
#   - Runs on GPU (4-6GB VRAM)
#   - Automatically downloads on first use
#
# USAGE:
#   qwen-tts-clone \
#     --reference audio.wav \
#     --reference-text "Hola, esto es una prueba" \
#     --target-text "Buenos días, bienvenidos" \
#     --language Spanish \
#     --output cloned.wav
#
# STORAGE:
#   - Models cached in: ~/.cache/huggingface/hub/
#   - Voice references: ~/voice-cloning/references/
#   - Generated audio: ~/voice-cloning/output/
#
# REQUIREMENTS:
#   - CUDA-capable GPU (tested on RTX 5080)
#   - ~6GB VRAM for inference
#   - Python 3.11+ with PyTorch
# =============================================================================

{
  config,
  lib,
  pkgs,
  ...
}:

let
  homeDir = config.home.homeDirectory;
  dotfilesDir = "${homeDir}/dotfiles";

in
{
  # ===========================================================================
  # Dependencies
  # ===========================================================================
  # BRUTAL APPROACH: Don't create separate Python env
  # qwen-tts will auto-install via pip on first run
  # This avoids Python version conflicts in buildEnv

  home.packages = with pkgs; [
    ffmpeg-full # Audio conversion
    python3 # System Python
    python3Packages.pip # pip for installing qwen-tts
  ];

  # ===========================================================================
  # Create directory structure for voice cloning
  # ===========================================================================
  home.activation.createVoiceCloningDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p $HOME/voice-cloning/references
    mkdir -p $HOME/voice-cloning/output
    mkdir -p $HOME/.cache/huggingface
  '';

  # ===========================================================================
  # Symlink qwen-tts-clone script
  # ===========================================================================
  home.file.".local/bin/qwen-tts-clone".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/scripts/qwen-tts-clone";
}
