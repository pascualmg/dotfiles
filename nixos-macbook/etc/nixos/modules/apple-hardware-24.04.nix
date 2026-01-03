# =============================================================================
# MODULO: Apple Hardware - MacBook Pro 13,2 (2016) - NixOS 24.04
# =============================================================================
# Configuracion hardware para MacBook Pro 13" con Touch Bar
# Compatible con NixOS 24.04 (24.05 tiene problemas de arranque)
#
# ESTRATEGIA:
#   Este modulo COMPLEMENTA los perfiles de nixos-hardware, NO los reemplaza.
#   El configuration.nix debe importar:
#     - nixos-hardware apple/macbook-pro (base Apple + Intel + laptop)
#     - nixos-hardware common/pc/ssd (optimizaciones SSD)
#
#   Este modulo agrega lo ESPECIFICO del MacBook Pro 13,2:
#     - SPI Keyboard/Trackpad (applespi driver)
#     - Touch Bar (tiny-dfr daemon)
#     - WiFi Broadcom BCM43602 (broadcom_sta driver)
#     - HiDPI para Retina 227 DPI
#     - Audio quirks Intel HDA + Apple
#
# WIFI BROADCOM - PROBLEMA CONOCIDO:
#   El WiFi BCM43602 detecta redes pero NO conecta en Live USB.
#   Despues de instalar con esta config, broadcom_sta deberia funcionar.
#   Si no funciona, usar USB WiFi/Ethernet como fallback.
#
# Hardware especifico MacBook Pro 13,2:
#   - CPU: Intel Core i5/i7-6xxx (Skylake)
#   - Display: 13.3" Retina 2560x1600 (227 DPI)
#   - GPU: Intel Iris Graphics 550 (GT3e)
#   - Input: Apple SPI keyboard + Force Touch trackpad
#   - Touch Bar: OLED con T1 chip
#   - WiFi: Broadcom BCM43602 (driver propietario wl/broadcom_sta)
#   - Ports: 4x Thunderbolt 3 (USB-C)
#
# DIAGNOSTICO:
#   - macbook-diag: Diagnostico completo hardware
#   - macbook-info: Informacion del sistema
#   - touchbar-status: Estado Touch Bar
#   - wifi-debug: Debug WiFi Broadcom
# =============================================================================

{ config, pkgs, lib, ... }:

{
  # ===========================================================================
  # KERNEL: Modulos especificos MacBook Pro 13,2
  # ===========================================================================

  boot = {
    # Kernel para NixOS 24.04
    # NOTA: linuxPackages_latest puede causar incompatibilidades
    # Usar linuxPackages_6_6 (LTS) o linuxPackages_6_7 para estabilidad
    kernelPackages = lib.mkDefault pkgs.linuxPackages_6_6;

    # Modulos SPI para teclado/trackpad Apple
    # Orden de carga importa: intel_lpss_pci -> spi_pxa2xx_platform -> applespi
    kernelModules = [
      # SPI Bus (CRITICO para teclado/trackpad)
      "intel_lpss_pci"        # Intel Low Power Subsystem PCI
      "spi_pxa2xx_platform"   # Plataforma SPI
      "applespi"              # Driver Apple SPI (teclado + trackpad)

      # Touch Bar via iBridge (puede no cargar en todos los kernels)
      "apple-ibridge"         # Controlador iBridge
      "apple-ib-tb"           # Touch Bar

      # Thunderbolt 3
      "thunderbolt"

      # WiFi Broadcom (cargado via wl module)
      # "wl"  # NO agregar aqui, se carga automaticamente
    ];

    # Modulos initrd para arranque temprano
    # Permite teclado en LUKS prompt, etc
    initrd.kernelModules = [
      "intel_lpss_pci"
      "spi_pxa2xx_platform"
    ];

    initrd.availableKernelModules = [
      "xhci_pci"        # USB 3.0 / Thunderbolt 3
      "ahci"            # SATA
      "nvme"            # NVMe SSD
      "usb_storage"     # USB storage
      "sd_mod"          # SCSI disk
      "thunderbolt"     # TB3
    ];

    # Parametros kernel especificos MacBook 13,2
    kernelParams = [
      # Backlight: usar driver nativo Apple
      "acpi_backlight=native"

      # Intel Graphics optimizations
      "i915.enable_fbc=1"         # Framebuffer compression
      "i915.enable_psr=1"         # Panel self-refresh
      "i915.fastboot=1"           # Reduce flickering at boot

      # Desactivar PSR si hay flickering (descomentar si necesario)
      # "i915.enable_psr=0"
    ];

    # =========================================================================
    # WIFI BROADCOM BCM43602 - CONFIGURACION CRITICA
    # =========================================================================
    # El BCM43602 requiere el driver propietario broadcom_sta (modulo wl)
    # Los drivers open-source (b43, brcmfmac, etc) NO funcionan con este chip
    #
    # PROBLEMA CONOCIDO: En Live USB detecta redes pero no conecta
    # SOLUCION: Despues de instalar, el driver deberia funcionar mejor

    extraModulePackages = with config.boot.kernelPackages; [
      broadcom_sta
    ];

    # Blacklist drivers Broadcom open-source (CONFLICTO con wl)
    # CRITICO: Sin esto, los drivers open-source cargan primero y bloquean wl
    blacklistedKernelModules = [
      "b43"
      "b43legacy"
      "bcma"
      "brcmsmac"
      "brcmfmac"
      "ssb"
      "bcm43xx"
    ];

    # Audio Intel HDA con quirks MacBook Pro
    extraModprobeConfig = ''
      # Intel HDA para MacBook Pro 13" 2016
      options snd-hda-intel model=mbp13
      options snd-hda-intel power_save=1

      # Broadcom WiFi power management (puede ayudar con conexion)
      options wl roam_off=1
    '';
  };

  # ===========================================================================
  # HARDWARE ENABLEMENT
  # ===========================================================================

  hardware = {
    # Firmware propietario (CRITICO para WiFi y otros)
    enableAllFirmware = true;
    enableRedistributableFirmware = true;

    # Intel CPU microcode
    cpu.intel.updateMicrocode = true;

    # Thunderbolt 3 device authorization
    bolt.enable = true;

    # Intel Graphics (Iris 550)
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        intel-media-driver      # VAAPI moderno (iHD)
        intel-vaapi-driver      # VAAPI legacy (i965)
        vaapiVdpau
        libvdpau-va-gl
      ];
    };

    # Bluetooth (Broadcom integrado)
    bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
        };
      };
    };

    # Sensor luz ambiental
    sensor.iio.enable = true;
  };

  # ===========================================================================
  # SERVICES: Input y Display
  # ===========================================================================

  services.xserver = {
    # Driver Intel moderno (modesetting con kernel)
    videoDrivers = [ "modesetting" ];

    # Trackpad Force Touch con libinput
    libinput = {
      enable = true;
      touchpad = {
        naturalScrolling = true;
        accelProfile = "adaptive";
        accelSpeed = "0.3";
        tapping = true;
        tappingDragLock = true;
        clickMethod = "clickfinger";    # Force Touch style
        disableWhileTyping = true;
        scrollMethod = "twofinger";
      };
    };

    # DPI para Retina 2560x1600 @ 13.3"
    dpi = 227;
  };

  # Backlight control
  services.illum.enable = true;

  # Control termico Intel
  services.thermald.enable = true;

  # Firmware updates
  services.fwupd.enable = true;

  # UPower para bateria
  services.upower = {
    enable = true;
    percentageLow = 15;
    percentageCritical = 5;
    criticalPowerAction = "Hibernate";
  };

  # ===========================================================================
  # AUDIO: PipeWire con quirks MacBook
  # ===========================================================================

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;

    extraConfig.pipewire."10-macbook-audio" = {
      "context.properties" = {
        "default.clock.rate" = 48000;
        "default.clock.quantum" = 1024;
        "default.clock.min-quantum" = 32;
        "default.clock.max-quantum" = 2048;
      };
    };
  };

  # Desactivar PulseAudio (usar PipeWire)
  services.pulseaudio.enable = false;

  # Realtime audio scheduling
  security.rtkit.enable = true;

  # ===========================================================================
  # TOUCH BAR: tiny-dfr daemon
  # ===========================================================================
  # tiny-dfr proporciona funciones F1-F12 en el Touch Bar
  # Si no esta disponible en nixpkgs 24.04, se puede omitir

  systemd.services.tiny-dfr = {
    description = "Apple Touch Bar Function Row Daemon";
    documentation = [ "https://github.com/kekrby/tiny-dfr" ];
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-udev-settle.service" ];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.tiny-dfr}/bin/tiny-dfr";
      Restart = "on-failure";
      RestartSec = "5s";
    };

    # No fallar si tiny-dfr no esta disponible
    unitConfig = {
      ConditionPathExists = "${pkgs.tiny-dfr}/bin/tiny-dfr";
    };
  };

  # ===========================================================================
  # POWER MANAGEMENT: TLP para laptop
  # ===========================================================================

  services.tlp = {
    enable = true;
    settings = {
      # CPU Intel Skylake
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

      # Limites P-State en bateria
      CPU_MIN_PERF_ON_BAT = 0;
      CPU_MAX_PERF_ON_BAT = 75;

      # Intel GPU
      INTEL_GPU_MIN_FREQ_ON_BAT = 300;
      INTEL_GPU_MAX_FREQ_ON_BAT = 800;

      # USB autosuspend DESACTIVADO (estabilidad TB3 y USB WiFi)
      USB_AUTOSUSPEND = 0;

      # WiFi power save
      WIFI_PWR_ON_AC = "off";
      WIFI_PWR_ON_BAT = "on";

      # Runtime PM
      RUNTIME_PM_ON_AC = "on";
      RUNTIME_PM_ON_BAT = "auto";
    };
  };

  # ===========================================================================
  # UDEV: Reglas hardware Apple
  # ===========================================================================

  services.udev.extraRules = ''
    # Apple SPI devices
    SUBSYSTEM=="spi", KERNEL=="spidev*", GROUP="input", MODE="0660"

    # Touch Bar USB
    SUBSYSTEM=="usb", ATTRS{idVendor}=="05ac", ATTRS{idProduct}=="8600", GROUP="video", MODE="0664"

    # Backlight permisos (permite control sin sudo)
    ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="intel_backlight", RUN+="${pkgs.coreutils}/bin/chmod 666 /sys/class/backlight/intel_backlight/brightness"

    # Broadcom WiFi (puede ayudar con permisos)
    SUBSYSTEM=="net", ACTION=="add", DRIVERS=="wl", ATTR{dev_id}=="0x0", ATTR{type}=="1", NAME="wlan0"
  '';

  # ===========================================================================
  # ENVIRONMENT: HiDPI Variables
  # ===========================================================================

  environment.variables = {
    # GTK HiDPI
    GDK_SCALE = "2";
    GDK_DPI_SCALE = "0.5";

    # Qt HiDPI
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    QT_ENABLE_HIGHDPI_SCALING = "1";

    # Cursor
    XCURSOR_SIZE = "48";

    # Intel VAAPI
    LIBVA_DRIVER_NAME = "iHD";
  };

  # ===========================================================================
  # FONTS: Optimizacion Retina
  # ===========================================================================

  fonts.fontconfig = {
    enable = true;
    antialias = true;
    hinting = {
      enable = true;
      style = "slight";
    };
    subpixel.rgba = "rgb";
  };

  # ===========================================================================
  # PACKAGES: Herramientas hardware y scripts diagnostico
  # ===========================================================================

  environment.systemPackages = with pkgs; [
    # Touch Bar
    tiny-dfr

    # Thunderbolt
    bolt

    # Intel GPU
    intel-gpu-tools
    libva-utils

    # Power
    powertop
    acpi

    # Audio
    alsa-utils
    pavucontrol
    pulsemixer

    # Backlight
    brightnessctl
    light

    # Bluetooth
    bluez
    bluez-tools
    blueman

    # WiFi (IMPORTANTE para debug)
    wirelesstools
    iw
    wpa_supplicant

    # Hardware info
    pciutils
    usbutils
    lshw
    dmidecode
    inxi
    lm_sensors

    # =========================================================================
    # SCRIPTS DIAGNOSTICO
    # =========================================================================

    # Script: Info sistema
    (writeShellScriptBin "macbook-info" ''
      #!/bin/bash
      echo "=== MACBOOK PRO 13,2 SYSTEM INFO ==="
      echo ""
      echo "Model: $(cat /sys/class/dmi/id/product_name 2>/dev/null || echo 'MacBook Pro 13,2')"
      echo "CPU: $(grep 'model name' /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)"
      echo "Memory: $(free -h | grep Mem | awk '{print $2}')"
      echo "Kernel: $(uname -r)"
      echo "NixOS: $(nixos-version 2>/dev/null || echo 'unknown')"
      echo ""
      echo "Display: 2560x1600 @ 227 DPI (Retina)"
      echo "Scaling: ''${GDK_SCALE:-1}x"
      echo ""
      echo "Storage: $(df -h / | tail -1 | awk '{print $2 " total, " $4 " free"}')"
      echo ""
      echo "Battery: $(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo 'N/A')%"
      echo ""
      echo "WiFi: $(iw dev 2>/dev/null | grep Interface | awk '{print $2}' || echo 'N/A')"
      echo ""
      echo "Touch Bar: $(systemctl is-active tiny-dfr 2>/dev/null || echo 'unknown')"
      echo ""
      echo "Commands: macbook-diag, touchbar-status, wifi-debug"
    '')

    # Script: Diagnostico hardware completo
    (writeShellScriptBin "macbook-diag" ''
      #!/bin/bash
      echo "=== MACBOOK PRO 13,2 HARDWARE DIAGNOSTICS ==="
      echo ""

      echo "=== 1. SPI KEYBOARD/TRACKPAD ==="
      for mod in applespi spi_pxa2xx_platform intel_lpss_pci; do
        if lsmod | grep -q "^$mod\|^$(echo $mod | tr '_' '-')"; then
          echo "[OK] $mod loaded"
        else
          echo "[FAIL] $mod NOT loaded"
        fi
      done
      echo ""

      echo "=== 2. TOUCH BAR ==="
      if lsmod | grep -q "apple_ib\|apple-ib"; then
        echo "[OK] iBridge modules loaded"
      else
        echo "[WARN] iBridge modules missing (may not affect function)"
      fi
      if systemctl is-active tiny-dfr &>/dev/null; then
        echo "[OK] tiny-dfr running"
      else
        echo "[INFO] tiny-dfr not running (Touch Bar may show media controls)"
      fi
      echo ""

      echo "=== 3. WIFI (Broadcom BCM43602) ==="
      if lsmod | grep -q "^wl"; then
        echo "[OK] wl (broadcom_sta) driver loaded"
      else
        echo "[FAIL] wl driver NOT loaded - WiFi won't work"
        echo "       Check: dmesg | grep -i broadcom"
      fi
      # Verificar que drivers conflictivos NO esten cargados
      for bad in b43 b43legacy bcma brcmsmac brcmfmac ssb; do
        if lsmod | grep -q "^$bad"; then
          echo "[WARN] $bad loaded - conflicts with wl!"
        fi
      done
      # Verificar interfaz
      if ip link | grep -q "wl\|wlan"; then
        IFACE=$(ip link | grep -o "wl[a-z0-9]*\|wlan[0-9]*" | head -1)
        echo "[OK] WiFi interface: $IFACE"
        STATE=$(cat /sys/class/net/$IFACE/operstate 2>/dev/null || echo "unknown")
        echo "     State: $STATE"
      else
        echo "[FAIL] No WiFi interface found"
      fi
      echo ""

      echo "=== 4. AUDIO ==="
      if aplay -l 2>/dev/null | grep -qi "intel\|hda"; then
        echo "[OK] Intel HDA detected"
      else
        echo "[WARN] Audio device not detected"
      fi
      if pactl info &>/dev/null; then
        echo "[OK] PipeWire/PulseAudio running"
      else
        echo "[FAIL] Audio server not running"
      fi
      echo ""

      echo "=== 5. GRAPHICS (Intel Iris 550) ==="
      if lsmod | grep -q "i915"; then
        echo "[OK] i915 driver loaded"
      else
        echo "[FAIL] i915 not loaded"
      fi
      if [ -f /sys/class/drm/card0/device/vendor ]; then
        echo "[OK] DRM device present"
      fi
      echo ""

      echo "=== 6. THUNDERBOLT ==="
      if lsmod | grep -q thunderbolt; then
        echo "[OK] Thunderbolt module loaded"
      else
        echo "[WARN] Thunderbolt module missing"
      fi
      echo ""

      echo "=== 7. SENSORS ==="
      sensors 2>/dev/null | grep -E "Core|temp" | head -4 || echo "[INFO] Run: sudo sensors-detect"
      echo ""

      echo "=== DIAGNOSTICS COMPLETE ==="
    '')

    # Script: Debug WiFi Broadcom
    (writeShellScriptBin "wifi-debug" ''
      #!/bin/bash
      echo "=== BROADCOM BCM43602 WIFI DEBUG ==="
      echo ""

      echo "=== KERNEL MODULES ==="
      echo "wl (broadcom_sta):"
      lsmod | grep -E "^wl\s" || echo "  NOT LOADED"
      echo ""
      echo "Conflicting modules (should be empty):"
      lsmod | grep -E "^(b43|bcma|brcm|ssb)" || echo "  (none - good)"
      echo ""

      echo "=== PCI DEVICE ==="
      lspci | grep -i "network\|broadcom" || echo "  Not found"
      echo ""

      echo "=== NETWORK INTERFACES ==="
      ip link show | grep -E "wl|wlan"
      echo ""

      echo "=== WIFI STATUS (NetworkManager) ==="
      nmcli device status 2>/dev/null | grep -i wifi || echo "  (nmcli not available or no WiFi)"
      echo ""

      echo "=== AVAILABLE NETWORKS ==="
      nmcli device wifi list 2>/dev/null | head -10 || echo "  (cannot scan)"
      echo ""

      echo "=== DMESG (last WiFi messages) ==="
      dmesg | grep -i "wl\|broadcom\|brcm\|wlan" | tail -10
      echo ""

      echo "=== TROUBLESHOOTING ==="
      echo "If WiFi detects networks but won't connect:"
      echo "  1. sudo systemctl restart NetworkManager"
      echo "  2. nmcli device wifi connect 'SSID' password 'PASSWORD'"
      echo "  3. If still failing, try USB WiFi adapter"
      echo ""
      echo "To reload driver:"
      echo "  sudo modprobe -r wl && sudo modprobe wl"
    '')

    # Script: Touch Bar status
    (writeShellScriptBin "touchbar-status" ''
      #!/bin/bash
      echo "=== TOUCH BAR STATUS ==="
      echo ""
      echo "Kernel modules:"
      lsmod | grep -E "apple.*(ib|tb)" || echo "  (none loaded - using default Touch Bar)"
      echo ""
      echo "Service:"
      systemctl status tiny-dfr --no-pager 2>/dev/null | head -5 || echo "  tiny-dfr not installed"
      echo ""
      echo "USB devices:"
      lsusb | grep -i apple || echo "  (no Apple USB devices)"
      echo ""
      echo "Control:"
      echo "  sudo systemctl start tiny-dfr   # Start function keys"
      echo "  sudo systemctl stop tiny-dfr    # Stop (use default Touch Bar)"
      echo "  sudo systemctl restart tiny-dfr # Restart"
    '')
  ];
}
