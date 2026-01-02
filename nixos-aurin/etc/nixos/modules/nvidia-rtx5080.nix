# ==============================================================================
# NVIDIA RTX 5080 - Configuracion especifica para Aurin
# ==============================================================================
#
# CRITICO: La RTX 5080 (Blackwell, Q1 2025) es TAN nueva que:
# - Drivers propietarios (575.51.02) NO la soportan
# - Solo drivers OPEN funcionan
# - Requiere parametros especiales del kernel
#
# Si cambias open = false, X11 NO arrancara.
# Probado 2025-12-09: "GPU not supported" con drivers propietarios.
#
# Este modulo es PORTABLE: si mueves la RTX 5080 a otra maquina,
# solo necesitas importar este archivo en su configuration.nix
#
# ==============================================================================

{ config, pkgs, ... }:

{
  # ===== ACELERACION GRAFICA =====
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # Necesario para Steam y aplicaciones 32-bit
    extraPackages = with pkgs; [
      nvidia-vaapi-driver # Aceleracion de video
      libva-vdpau-driver  # Antes: vaapiVdpau (renombrado)
      libvdpau-va-gl
      vulkan-loader
    ];
  };

  # ===== DRIVER NVIDIA =====
  hardware.nvidia = {
    # CRITICO: RTX 5080 NO soportada en drivers propietarios (575.51.02)
    # NO cambiar a false sin verificar que hay drivers nuevos que la soporten
    open = true;

    # Beta necesario para soporte RTX 50xx
    package = config.boot.kernelPackages.nvidiaPackages.beta;

    # Configuracion estandar
    modesetting.enable = true;
    nvidiaSettings = true;
    forceFullCompositionPipeline = true;
    powerManagement.enable = true;
    nvidiaPersistenced = true;
  };

  # ===== NVIDIA CONTAINER TOOLKIT (Docker con GPU) =====
  hardware.nvidia-container-toolkit.enable = true;

  # ===== PARAMETROS KERNEL NVIDIA =====
  boot.kernelParams = [
    # Modesetting (obligatorio)
    "nvidia-drm.modeset=1"
    "nvidia-drm.fbdev=1"

    # Preservar VRAM en suspend/resume
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"

    # Firmware GPU
    "nvidia.NVreg_EnableGpuFirmware=1"

    # CRITICO: Permite GPUs no oficialmente soportadas (RTX 5080)
    "nvidia.NVreg_OpenRmEnableUnsupportedGpus=1"

    # Resolucion de video (tu monitor ultrawide)
    "video=5120x1440@120"

    # Desactivar nouveau (driver open source alternativo)
    "nouveau.modeset=0"
  ];

  # ===== MODULOS KERNEL =====
  boot.initrd.kernelModules = [
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
  ];

  boot.blacklistedKernelModules = [ "nouveau" ];

  # ===== X11 VIDEO DRIVER =====
  services.xserver.videoDrivers = [ "nvidia" ];

  # ===== VARIABLES DE ENTORNO NVIDIA =====
  environment.sessionVariables = {
    # Driver de aceleracion de video
    LIBVA_DRIVER_NAME = "nvidia";

    # Forzar uso de NVIDIA para GLX
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";

    # Sincronizacion vertical
    __GL_SYNC_TO_VBLANK = "1";

    # G-Sync / VRR
    __GL_GSYNC_ALLOWED = "1";
    __GL_VRR_ALLOWED = "1";

    # Optimizaciones de rendimiento
    __GL_THREADED_OPTIMIZATIONS = "1";

    # CUDA (para aplicaciones que usan GPU)
    CUDA_VISIBLE_DEVICES = "0";
    NVIDIA_DRIVER_CAPABILITIES = "all";

    # Desactivar OSD (molesto en streaming)
    __GL_SHOW_GRAPHICS_OSD = "0";
  };
}
