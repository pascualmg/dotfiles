# =============================================================================
# HARDWARE/NVIDIA/RTX2060.NIX - NVIDIA RTX 2060 (Turing)
# =============================================================================
# Drivers propietarios estables para RTX 2060 y GPUs similares:
#   - RTX 2060, 2070, 2080, etc. (Turing)
#   - GTX 1000 series (Pascal)
#   - Cualquier GPU que necesite drivers propietarios (no open)
#
# Caracteristicas:
#   - Drivers propietarios stable (no open)
#   - forceFullCompositionPipeline para tearing-free
#   - Variables de entorno NVIDIA
#   - nvidia-vaapi-driver para aceleracion video
# =============================================================================

{ config, pkgs, lib, ... }:

{
  # ===== VIDEO DRIVERS =====
  services.xserver.videoDrivers = [ "nvidia" ];

  # ===== HARDWARE GRAPHICS =====
  hardware = {
    enableAllFirmware = true;
    graphics = {
      enable = true;
      enable32Bit = true;
    };
    nvidia = {
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      modesetting.enable = true;
      open = false;  # Drivers propietarios (GPU antigua, no RTX 50xx)
      nvidiaSettings = true;
      forceFullCompositionPipeline = true;  # Tearing-free
    };
  };

  # ===== ENVIRONMENT VARIABLES =====
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    __GL_SYNC_TO_VBLANK = "1";
    __GL_GSYNC_ALLOWED = "1";
    __GL_VRR_ALLOWED = "1";
  };

  # ===== PAQUETES NVIDIA =====
  environment.systemPackages = with pkgs; [
    nvidia-vaapi-driver
    nvtopPackages.full
    vulkan-tools
    mesa-demos
  ];
}
