# =============================================================================
# MODULO: Apple Hardware - MacBook Pro 13,2 (2016)
# =============================================================================
# Configuracion hardware para MacBook Pro 13" con Touch Bar
#
# ESTRATEGIA:
#   Este modulo COMPLEMENTA los perfiles de nixos-hardware, NO los reemplaza.
#   El configuration.nix debe importar los perfiles base de nixos-hardware:
#     - nixos-hardware.nixosModules.apple-macbook-pro (base Apple + Intel + laptop)
#     - nixos-hardware.nixosModules.common-pc-ssd (optimizaciones SSD)
#
#   Este modulo agrega lo ESPECIFICO del MacBook Pro 13,2 que NO esta en
#   nixos-hardware (ya que no existe perfil 13-2):
#     - SPI Keyboard/Trackpad (applespi driver)
#     - Touch Bar (T1 chip drivers + tiny-dfr daemon)
#     - WiFi Broadcom BCM43602 (broadcom_sta driver)
#     - HiDPI para Retina 227 DPI
#     - Audio quirks Intel HDA + Apple
#
# Hardware especifico MacBook Pro 13,2:
#   - CPU: Intel Core i5/i7-6xxx (Skylake)
#   - Display: 13.3" Retina 2560x1600 (227 DPI)
#   - GPU: Intel Iris Graphics 550 (GT3e)
#   - Input: Apple SPI keyboard + Force Touch trackpad
#   - Touch Bar: OLED con T1 chip (NO T2)
#   - WiFi: Broadcom BCM43602 (requiere driver propietario)
#   - Ports: 4x Thunderbolt 3 (USB-C)
#
# Dependencias nixos-hardware (importar en configuration.nix):
#   - apple-macbook-pro: mbpfan, facetimehd, cpu/intel, pc/laptop
#   - common-pc-ssd: fstrim automatico
#
# Touch Bar (T1 chip):
#   - Usa drivers de: https://github.com/parport0/mbp-t1-touchbar-driver
#   - Modulos: apple-ibridge, apple-ib-tb, apple-ib-als
#   - Daemon: tiny-dfr para mostrar F1-F12 y Escape
#
# Comandos diagnostico:
#   - macbook-diag: Diagnostico completo hardware
#   - macbook-info: Informacion del sistema
#   - touchbar-status: Estado Touch Bar
#   - touchbar-rebind: Forzar rebind USB del iBridge
# =============================================================================

{ config, pkgs, lib, ... }:

let
  # ===========================================================================
  # T1 TOUCH BAR KERNEL MODULES
  # ===========================================================================
  # Driver out-of-tree para el chip T1 de MacBook Pro 2016-2017
  # Repositorio: https://github.com/parport0/mbp-t1-touchbar-driver
  #
  # Compila tres modulos:
  #   - apple-ibridge: Controlador principal iBridge (T1 chip)
  #   - apple-ib-tb: Touch Bar display
  #   - apple-ib-als: Ambient Light Sensor
  #
  # NOTA: Este driver es para T1 (2016-2017), NO para T2 (2018+)
  # ===========================================================================

  apple-t1-touchbar-driver = config.boot.kernelPackages.callPackage
    ({ stdenv, lib, fetchFromGitHub, kernel }:
      stdenv.mkDerivation rec {
        pname = "apple-t1-touchbar-driver";
        version = "6.8.0-unstable-2024-03-24";

        src = fetchFromGitHub {
          owner = "parport0";
          repo = "mbp-t1-touchbar-driver";
          rev = "6d62f38c6b2c27da1becd311ad7b15826e58ed41";
          sha256 = "sha256-3YjShwyUBsqTRK/c3f4AVZJswlwpr3DoeDZEBZ3RkdQ=";
        };

        nativeBuildInputs = kernel.moduleBuildDependencies;

        makeFlags = [
          "KDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
        ];

        installPhase = ''
          runHook preInstall

          # Instalar modulos en la ruta estandar de NixOS
          install -D -m 644 apple-ibridge.ko \
            $out/lib/modules/${kernel.modDirVersion}/extra/apple-ibridge.ko
          install -D -m 644 apple-ib-tb.ko \
            $out/lib/modules/${kernel.modDirVersion}/extra/apple-ib-tb.ko
          install -D -m 644 apple-ib-als.ko \
            $out/lib/modules/${kernel.modDirVersion}/extra/apple-ib-als.ko

          runHook postInstall
        '';

        meta = with lib; {
          description = "Apple T1 Touch Bar driver for MacBook Pro 2016-2017";
          homepage = "https://github.com/parport0/mbp-t1-touchbar-driver";
          license = licenses.gpl2Only;
          platforms = platforms.linux;
          maintainers = [ ];
        };
      }
    ) { };

in
{
  # ===========================================================================
  # KERNEL: Modulos especificos MacBook Pro 13,2
  # ===========================================================================
  # nixos-hardware NO incluye drivers SPI para teclado/trackpad del 13,2
  # ni configuracion Touch Bar, porque no existe perfil 13-2

  boot = {
    # Kernel latest para mejor soporte Apple SPI
    # CRITICO: Kernel >= 6.0 para applespi estable
    kernelPackages = pkgs.linuxPackages_latest;

    # Modulos SPI para teclado/trackpad Apple
    # Orden de carga importa: intel_lpss_pci -> spi_pxa2xx_platform -> applespi
    kernelModules = [
      # SPI Bus (CRITICO para teclado/trackpad)
      "intel_lpss_pci"        # Intel Low Power Subsystem PCI
      "spi_pxa2xx_platform"   # Plataforma SPI
      "applespi"              # Driver Apple SPI (teclado + trackpad)

      # Touch Bar via iBridge T1
      # Estos modulos vienen del paquete apple-t1-touchbar-driver
      "apple-ibridge"         # Controlador iBridge (T1 chip)
      "apple-ib-tb"           # Touch Bar display
      "apple-ib-als"          # Ambient Light Sensor (opcional pero util)

      # Thunderbolt 3
      "thunderbolt"
    ];

    # Modulos initrd para arranque temprano (teclado disponible en LUKS, etc)
    initrd.kernelModules = [
      "intel_lpss_pci"
      "spi_pxa2xx_platform"
    ];

    # Parametros kernel especificos MacBook 13,2
    kernelParams = [
      # Backlight: usar driver nativo Apple
      "acpi_backlight=native"

      # Intel Graphics optimizations
      "i915.enable_fbc=1"         # Framebuffer compression
      "i915.enable_psr=1"         # Panel self-refresh
      "i915.fastboot=1"           # Reduce flickering at boot
    ];

    # Modulos extra del kernel compilados out-of-tree
    extraModulePackages = [
      # Touch Bar T1 drivers
      apple-t1-touchbar-driver

      # WiFi BCM43602: Driver wl (broadcom_sta) NO FUNCIONA en kernel 6.x
      # Compila pero falla en runtime: "wl driver failed with code 1"
      # El driver propietario es incompatible con APIs modernas del kernel.
      # Solucion: Usar USB WiFi dongle (ej: TP-Link con RTL8xxxu)
    ];

    # Blacklist drivers Broadcom open-source que interfieren con USB dongle
    blacklistedKernelModules = [
      "b43" "b43legacy" "bcma" "brcmsmac" "ssb"
      # NOTA: NO blacklistear brcmfmac - algunos dongles USB lo usan
    ];

    # Audio Intel HDA con quirks MacBook Pro
    extraModprobeConfig = ''
      options snd-hda-intel model=mbp13
      options snd-hda-intel power_save=1
    '';
  };

  # ===========================================================================
  # HARDWARE: Complementos a nixos-hardware
  # ===========================================================================
  # nixos-hardware/apple ya habilita: facetimehd, mbpfan
  # nixos-hardware/common/cpu/intel ya habilita: microcode, intel GPU
  # Aqui agregamos lo que falta para 13,2

  # FaceTime HD Camera - firmware necesario
  hardware.facetimehd.enable = true;

  # Thunderbolt 3 device authorization (bolt)
  services.hardware.bolt.enable = true;

  hardware = {
    # Intel Graphics extras (Iris 550)
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        intel-media-driver      # VAAPI moderno (iHD)
        intel-vaapi-driver      # VAAPI legacy (i965)
        libva-vdpau-driver      # Antes: vaapiVdpau
        libvdpau-va-gl
      ];
    };

    # Bluetooth (Broadcom integrado)
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

    # Sensor luz ambiental
    sensor.iio.enable = true;
  };

  # ===========================================================================
  # SERVICES: Input y Display
  # ===========================================================================

  services.xserver = {
    # Driver Intel moderno
    videoDrivers = [ "modesetting" ];

    # DPI para Retina 2560x1600 @ 13.3"
    dpi = 227;
  };

  # Trackpad Force Touch con libinput (opcion movida de xserver)
  services.libinput = {
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

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;

  # ===========================================================================
  # TOUCH BAR: tiny-dfr daemon + udev rules
  # ===========================================================================
  # El chip T1 de MacBook Pro 13,2 (2016) requiere:
  #   1. Modulos kernel: apple-ibridge, apple-ib-tb (compilados arriba)
  #   2. Daemon: tiny-dfr para mostrar teclas de funcion
  #   3. Udev rules: para rebind automatico del dispositivo USB
  #
  # El daemon tiny-dfr muestra F1-F12 y Escape en la Touch Bar.
  # El boton Fn fisico alterna entre F-keys y controles multimedia.
  #
  # ESTADO ACTUAL: T1 en RECOVERY MODE (05ac:1281)
  # El firmware del T1 esta corrupto. Hasta restaurarlo con Apple Configurator 2,
  # tiny-dfr no puede funcionar. Ver README.org seccion "T1 Touch Bar".
  #
  # Para reactivar cuando el T1 funcione:
  #   1. Verificar: lsusb | grep "05ac:8600"  (debe mostrar iBridge)
  #   2. Descomentar el bloque systemd.services.tiny-dfr abajo
  #   3. sudo nixos-rebuild switch
  # ===========================================================================

  # DESHABILITADO: T1 en recovery mode - descomentar cuando se restaure el firmware
  # systemd.services.tiny-dfr = {
  #   description = "Apple Touch Bar Function Row Daemon";
  #   documentation = [ "https://github.com/WhatAmISupposedToPutHere/tiny-dfr" ];
  #   wantedBy = [ "multi-user.target" ];
  #
  #   # Esperar a que udev y los modulos esten cargados
  #   after = [ "systemd-udev-settle.service" "systemd-modules-load.service" ];
  #   wants = [ "systemd-modules-load.service" ];
  #
  #   serviceConfig = {
  #     Type = "simple";
  #     ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";  # Esperar dispositivos USB
  #     ExecStart = "${pkgs.tiny-dfr}/bin/tiny-dfr";
  #     Restart = "on-failure";
  #     RestartSec = "5s";
  #
  #     # Reintentar varias veces si falla al inicio
  #     StartLimitIntervalSec = 60;
  #     StartLimitBurst = 5;
  #   };
  # };

  # ===========================================================================
  # POWER MANAGEMENT: TLP para laptop
  # ===========================================================================
  # nixos-hardware/common/pc/laptop habilita TLP por defecto
  # Aqui configuramos settings especificos Intel Skylake

  # Deshabilitar power-profiles-daemon (conflicto con TLP, GNOME lo activa)
  services.power-profiles-daemon.enable = false;

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

      # Desactivar USB autosuspend (estabilidad TB3)
      USB_AUTOSUSPEND = 0;

      # WiFi power save
      WIFI_PWR_ON_AC = "off";
      WIFI_PWR_ON_BAT = "on";
    };
  };

  # ===========================================================================
  # UDEV: Reglas hardware Apple + Touch Bar rebind
  # ===========================================================================

  services.udev.extraRules = ''
    # Apple SPI devices
    SUBSYSTEM=="spi", KERNEL=="spidev*", GROUP="input", MODE="0660"

    # Touch Bar USB - iBridge device
    # Vendor: 05ac (Apple), Product: 8600 (iBridge)
    SUBSYSTEM=="usb", ATTRS{idVendor}=="05ac", ATTRS{idProduct}=="8600", GROUP="video", MODE="0664"

    # Rebind automatico del iBridge cuando se detecta
    # Esto ayuda a que apple-ibridge tome control del dispositivo
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="05ac", ATTRS{idProduct}=="8600", \
      RUN+="${pkgs.bash}/bin/bash -c 'echo 1-3 > /sys/bus/usb/drivers_probe 2>/dev/null || true'"

    # Backlight permisos
    ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="intel_backlight", RUN+="${pkgs.coreutils}/bin/chmod 666 /sys/class/backlight/intel_backlight/brightness"
  '';

  # ===========================================================================
  # ENVIRONMENT: HiDPI Variables
  # ===========================================================================

  environment.variables = {
    # GTK - sin escalado de ventanas, solo DPI
    GDK_SCALE = "1";
    GDK_DPI_SCALE = "1";

    # Qt HiDPI - automático
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    QT_ENABLE_HIGHDPI_SCALING = "1";

    # Cursor (32 es normal, 48 es grande)
    XCURSOR_SIZE = "32";
    XCURSOR_THEME = "Adwaita";

    # Java apps
    _JAVA_OPTIONS = "-Dsun.java2d.uiScale=1.75";

    # Intel VAAPI
    LIBVA_DRIVER_NAME = "iHD";
  };

  # Xresources para Xft (fonts en X11)
  # DPI 168 = 1.75x del estándar 96 (punto medio para Retina 13")
  environment.etc."X11/Xresources".text = ''
    Xft.dpi: 168
    Xft.autohint: 0
    Xft.lcdfilter: lcddefault
    Xft.hintstyle: hintfull
    Xft.hinting: 1
    Xft.antialias: 1
    Xft.rgba: rgb
    Xcursor.size: 32
    Xcursor.theme: Adwaita
  '';

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
  # PACKAGES: Herramientas y scripts diagnostico
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

    # WiFi
    wirelesstools
    iw

    # Hardware info
    pciutils
    usbutils
    lshw
    dmidecode
    inxi
    lm_sensors

    # Script: Info sistema
    (writeShellScriptBin "macbook-info" ''
      #!/bin/bash
      echo "=== MACBOOK PRO 13,2 SYSTEM INFO ==="
      echo ""
      echo "Model: $(cat /sys/class/dmi/id/product_name 2>/dev/null || echo 'MacBook Pro')"
      echo "CPU: $(grep 'model name' /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)"
      echo "Memory: $(free -h | grep Mem | awk '{print $2}')"
      echo "Kernel: $(uname -r)"
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
      echo "Commands: macbook-diag, touchbar-status, touchbar-rebind"
    '')

    # Script: Diagnostico hardware
    (writeShellScriptBin "macbook-diag" ''
      #!/bin/bash
      echo "=== MACBOOK PRO 13,2 HARDWARE DIAGNOSTICS ==="
      echo ""

      echo "=== 1. SPI KEYBOARD/TRACKPAD ==="
      for mod in applespi spi_pxa2xx_platform intel_lpss_pci; do
        if lsmod | grep -q "^$mod\|^$(echo $mod | tr '_' '-')"; then
          echo "[OK] $mod"
        else
          echo "[FAIL] $mod NOT loaded"
        fi
      done
      echo ""

      echo "=== 2. TOUCH BAR (T1 iBridge) ==="
      for mod in apple_ibridge apple_ib_tb apple_ib_als; do
        mod_alt=$(echo $mod | tr '_' '-')
        if lsmod | grep -qE "^$mod|^$mod_alt"; then
          echo "[OK] $mod"
        else
          echo "[WARN] $mod NOT loaded"
        fi
      done
      echo ""
      echo "iBridge USB device:"
      lsusb | grep -i "8600\|iBridge" || echo "  [WARN] iBridge not found (05ac:8600)"
      echo ""
      echo "tiny-dfr service:"
      systemctl is-active tiny-dfr &>/dev/null && echo "[OK] tiny-dfr running" || echo "[FAIL] tiny-dfr not running"
      echo ""

      echo "=== 3. WIFI (Broadcom) ==="
      lsmod | grep -q "^wl" && echo "[OK] wl driver" || echo "[FAIL] wl driver missing"
      ip link | grep -q wlp && echo "[OK] WiFi interface found" || echo "[FAIL] No WiFi interface"
      echo ""

      echo "=== 4. AUDIO ==="
      aplay -l 2>/dev/null | grep -qi "intel\|hda" && echo "[OK] Intel HDA detected" || echo "[WARN] Audio issue"
      pactl info &>/dev/null && echo "[OK] PipeWire running" || echo "[FAIL] Audio server down"
      echo ""

      echo "=== 5. THUNDERBOLT ==="
      lsmod | grep -q thunderbolt && echo "[OK] TB3 module" || echo "[WARN] TB3 module missing"
      echo ""

      echo "=== 6. SENSORS ==="
      sensors 2>/dev/null | grep -E "Core|temp" | head -4 || echo "[INFO] Run: sudo sensors-detect"
      echo ""

      echo "=== COMPLETE ==="
    '')

    # Script: Touch Bar status
    (writeShellScriptBin "touchbar-status" ''
      #!/bin/bash
      echo "=== TOUCH BAR STATUS ==="
      echo ""
      echo "Kernel modules:"
      echo "  apple-ibridge: $(lsmod | grep -qE '^apple.ibridge' && echo 'LOADED' || echo 'NOT LOADED')"
      echo "  apple-ib-tb:   $(lsmod | grep -qE '^apple.ib.tb' && echo 'LOADED' || echo 'NOT LOADED')"
      echo "  apple-ib-als:  $(lsmod | grep -qE '^apple.ib.als' && echo 'LOADED' || echo 'NOT LOADED')"
      echo ""
      echo "USB iBridge device (05ac:8600):"
      lsusb | grep -i "8600\|iBridge" || echo "  NOT FOUND"
      echo ""
      echo "USB tree for iBridge:"
      lsusb -t 2>/dev/null | grep -A5 "8600" | head -6 || echo "  (run lsusb -t manually)"
      echo ""
      echo "Service status:"
      systemctl status tiny-dfr --no-pager 2>/dev/null | head -10
      echo ""
      echo "Commands:"
      echo "  touchbar-rebind    - Force USB rebind for iBridge"
      echo "  sudo systemctl restart tiny-dfr"
      echo "  sudo modprobe apple-ib-tb"
    '')

    # Script: Force rebind Touch Bar USB
    (writeShellScriptBin "touchbar-rebind" ''
      #!/bin/bash
      echo "=== TOUCH BAR USB REBIND ==="
      echo ""
      echo "This script forces the iBridge USB device to rebind to the apple-ibridge driver."
      echo "Run with sudo if needed."
      echo ""

      # Encontrar el bus/device del iBridge
      IBRIDGE=$(lsusb | grep "05ac:8600" | head -1)
      if [ -z "$IBRIDGE" ]; then
        echo "[ERROR] iBridge device (05ac:8600) not found!"
        echo "Check if T1 chip is in recovery mode:"
        lsusb | grep -i apple
        exit 1
      fi

      echo "Found: $IBRIDGE"
      echo ""

      # Extraer el puerto USB (tipicamente 1-3 para MacBook Pro 13,2)
      # Buscar en /sys/bus/usb/devices/
      USB_PORT=""
      for dev in /sys/bus/usb/devices/*/idProduct; do
        if [ -f "$dev" ] && [ "$(cat $dev 2>/dev/null)" = "8600" ]; then
          USB_PORT=$(dirname $dev | xargs basename)
          break
        fi
      done

      if [ -z "$USB_PORT" ]; then
        echo "[WARN] Could not determine USB port, trying default 1-3"
        USB_PORT="1-3"
      fi

      echo "USB port: $USB_PORT"
      echo ""

      echo "Unbinding and rebinding..."
      # Unbind
      echo "$USB_PORT" | sudo tee /sys/bus/usb/drivers/usb/unbind 2>/dev/null || true
      sleep 1

      # Rebind
      echo "$USB_PORT" | sudo tee /sys/bus/usb/drivers_probe 2>/dev/null || true
      sleep 1

      # Unbind HID interfaces if present (1-3:1.2 and 1-3:1.3)
      for iface in "$USB_PORT:1.2" "$USB_PORT:1.3"; do
        echo "$iface" | sudo tee /sys/bus/usb/drivers/usbhid/unbind 2>/dev/null || true
      done
      sleep 1

      # Reprobe interfaces
      for iface in "$USB_PORT:1.2" "$USB_PORT:1.3"; do
        echo "$iface" | sudo tee /sys/bus/usb/drivers_probe 2>/dev/null || true
      done

      echo ""
      echo "Restarting tiny-dfr..."
      sudo systemctl restart tiny-dfr

      echo ""
      echo "Done. Check with: touchbar-status"
    '')
  ];
}
