# =============================================================================
# MODULO: snd_hda_macbookpro - Audio Driver para MacBook Pro con CS8409
# =============================================================================
# Driver de audio para MacBooks con chip Cirrus Logic CS8409 HDA bridge.
# Reemplaza el driver del kernel que solo soporta Dell.
#
# Repositorio: https://github.com/davidjo/snd_hda_macbookpro
#
# Hardware soportado:
#   - MacBook Pro 13,1 (0x106b3300) - 2016 sin Touch Bar
#   - MacBook Pro 13,2 (0x106b3600) - 2016 con Touch Bar  <-- TU MODELO
#   - MacBook Pro 14,2 (0x106b3600) - 2017 13"
#   - MacBook Pro 14,3 (0x106b3900) - 2017 15"
#   - iMac 18,1/18,2/18,3/19,1 (0x106b0e00/0f00/1000)
#
# Amplificadores soportados:
#   - MAX98706 (MacBook Pro 2016-2017)
#   - SSM3515 (iMac 2017+)
#   - TAS5764L (algunos modelos)
#
# El problema con el driver del kernel:
#   - El driver oficial snd_hda_codec_cs8409 solo tiene quirks para Dell
#   - Tu MacBook (subsystem 0x106b3600) no tiene fixup, GPIO deshabilitado
#   - Este driver aplica la configuracion correcta para Apple
#
# USO:
#   1. Importar este modulo en configuration.nix
#   2. Ejecutar: sudo nixos-rebuild switch
#   3. Reiniciar
#   4. Verificar: lsmod | grep cs8409 (debe mostrar snd_hda_codec_cs8409)
#   5. speaker-test -c 2 deberia funcionar ahora
#
# DIAGNOSTICO:
#   - cat /proc/asound/card0/codec#0 | grep GPIO
#   - Debe mostrar: gpio_mask=0x0f, enable=1
#
# NOTA: Este driver reemplaza el modulo del kernel, no lo complementa.
# =============================================================================

{ config, pkgs, lib, ... }:

let
  # ===========================================================================
  # KERNEL MODULE: snd_hda_macbookpro
  # ===========================================================================
  # Compila el driver de audio de davidjo para MacBooks con CS8409.
  #
  # KERNEL 6.17+ BUILD PROCESS:
  # 1. Extraer sound/hda/ del kernel tarball
  # 2. Copiar Makefiles de davidjo (makefiles/)
  # 3. Aplicar patch_cs8409.c.diff y patch_cs8409.h.diff sobre codigo del kernel
  # 4. Copiar headers Apple (cirrus_apple.h, etc.) de patch_cirrus/
  # 5. Compilar con CONFIG_SND_HDA_CODEC_CS8409=m
  #
  # El parche agrega #include "cirrus_apple.h" que contiene todo el soporte Apple.
  # ===========================================================================

  snd-hda-macbookpro = config.boot.kernelPackages.callPackage
    ({ stdenv, lib, fetchFromGitHub, fetchurl, kernel, gnused, coreutils, xz, gnupatch }:

      let
        # Extraer version del kernel
        kernelVersion = kernel.version;
        majorVersion = lib.versions.major kernelVersion;
        minorVersion = lib.versions.minor kernelVersion;
        majorMinor = "${majorVersion}.${minorVersion}";

        # Para kernel 6.17+, la estructura de sound/hda cambio
        isKernel617Plus = (lib.toInt majorVersion) > 6 ||
                          ((lib.toInt majorVersion) == 6 && (lib.toInt minorVersion) >= 17);

        # URL para descargar fuentes del kernel
        kernelTarball = fetchurl {
          url = "https://cdn.kernel.org/pub/linux/kernel/v${majorVersion}.x/linux-${majorMinor}.tar.xz";
          sha256 = "0jzdvk3xdai1xsq0739hmf8rapw15dw5inarfvqizqx9bmha81li";
        };

      in
      stdenv.mkDerivation rec {
        pname = "snd-hda-macbookpro";
        version = "unstable-2025-01-04";

        src = fetchFromGitHub {
          owner = "davidjo";
          repo = "snd_hda_macbookpro";
          rev = "4926535d436fc8ed50bb6c96aecd7b40d26b656e";
          sha256 = "sha256-LNMNrZeTdws2bCd0YdaF9sp+ecJc4q4NCA7Ms37K07Y=";
        };

        nativeBuildInputs = kernel.moduleBuildDependencies ++ [
          gnused
          coreutils
          xz
          gnupatch
        ];

        inherit kernelTarball;

        buildPhase = ''
          runHook preBuild

          echo "========================================"
          echo "Building snd-hda-macbookpro for kernel ${kernelVersion}"
          echo "Kernel 6.17+ structure: ${if isKernel617Plus then "YES" else "NO"}"
          echo "========================================"

          # Crear directorio de build
          mkdir -p build

          # Extraer sound/hda del tarball del kernel
          echo "Extracting HDA sources from kernel tarball..."

          ${if isKernel617Plus then ''
            # Kernel 6.17+ usa sound/hda/
            xz -dc $kernelTarball | tar -xf - "linux-${majorMinor}/sound/hda/" 2>/dev/null || {
              echo "ERROR: Could not extract sound/hda from kernel tarball"
              exit 1
            }
            mv "linux-${majorMinor}/sound/hda" build/hda
          '' else ''
            # Kernel < 6.17 usa sound/pci/hda/
            xz -dc $kernelTarball | tar -xf - "linux-${majorMinor}/sound/pci/hda/" 2>/dev/null || {
              echo "ERROR: Could not extract sound/pci/hda from kernel tarball"
              exit 1
            }
            mv "linux-${majorMinor}/sound/pci/hda" build/hda
          ''}

          echo "HDA sources extracted:"
          ls -la build/hda/

          # Hacer escribibles
          chmod -R u+w build/

          ${if isKernel617Plus then ''
            # ================================================================
            # KERNEL 6.17+ BUILD PROCESS
            # ================================================================
            # La estructura es: sound/hda/codecs/cirrus/
            # El driver de davidjo parchea cs8409.c y cs8409.h del kernel
            # y agrega cirrus_apple.h con todo el codigo Apple
            # ================================================================

            echo ""
            echo "=== STEP 1: Replace Makefiles with davidjo versions ==="
            # Los Makefiles de davidjo solo compilan el modulo cs8409
            mv build/hda/Makefile build/hda/Makefile.orig
            mv build/hda/common/Makefile build/hda/common/Makefile.orig
            mv build/hda/codecs/Makefile build/hda/codecs/Makefile.orig
            mv build/hda/codecs/cirrus/Makefile build/hda/codecs/cirrus/Makefile.orig

            cp -v makefiles/Makefile build/hda/
            cp -v makefiles/Makefile_common build/hda/common/Makefile
            cp -v makefiles/Makefile_codecs build/hda/codecs/Makefile
            cp -v makefiles/Makefile_cirrus build/hda/codecs/cirrus/Makefile

            echo ""
            echo "=== STEP 2: Apply patches to kernel source files ==="
            # Los parches modifican cs8409.c y cs8409.h para agregar soporte Apple
            # patch_cs8409.c.diff agrega: #include "cirrus_apple.h" y llamada a cs8409_apple()
            # patch_cs8409.h.diff modifica definiciones del driver

            pushd build/hda > /dev/null

            echo "Applying patch_cs8409.c.diff..."
            patch -b -p1 < ../../patch_cs8409.c.diff
            if [ $? -ne 0 ]; then
              echo "ERROR: Failed to apply patch_cs8409.c.diff"
              echo "Trying with --ignore-whitespace..."
              patch -b -p1 --ignore-whitespace < ../../patch_cs8409.c.diff || {
                echo "FATAL: Could not apply C patch"
                exit 1
              }
            fi

            echo "Applying patch_cs8409.h.diff..."
            patch -b -p1 < ../../patch_cs8409.h.diff
            if [ $? -ne 0 ]; then
              echo "ERROR: Failed to apply patch_cs8409.h.diff"
              echo "Trying with --ignore-whitespace..."
              patch -b -p1 --ignore-whitespace < ../../patch_cs8409.h.diff || {
                echo "FATAL: Could not apply H patch"
                exit 1
              }
            fi

            popd > /dev/null

            echo ""
            echo "=== STEP 3: Copy Apple headers from patch_cirrus/ ==="
            # Estos archivos contienen todo el codigo para Apple:
            # - cirrus_apple.h: Driver principal Apple (incluido por cs8409.c parcheado)
            # - patch_cirrus_*.h: Tablas de inicializacion, I2C, etc.

            cp -v patch_cirrus/cirrus_apple.h build/hda/codecs/cirrus/
            cp -v patch_cirrus/patch_cirrus_boot84.h build/hda/codecs/cirrus/
            cp -v patch_cirrus/patch_cirrus_new84.h build/hda/codecs/cirrus/
            cp -v patch_cirrus/patch_cirrus_real84.h build/hda/codecs/cirrus/
            cp -v patch_cirrus/patch_cirrus_hda_generic_copy.h build/hda/codecs/cirrus/
            cp -v patch_cirrus/patch_cirrus_real84_i2c.h build/hda/codecs/cirrus/

            # Verificar que cirrus_apple.h existe (critico)
            if [ ! -f build/hda/codecs/cirrus/cirrus_apple.h ]; then
              echo "FATAL: cirrus_apple.h not copied!"
              exit 1
            fi

            echo ""
            echo "=== STEP 4: Verify patched files ==="
            echo "Checking for Apple include in cs8409.c..."
            grep -n "cirrus_apple.h" build/hda/codecs/cirrus/cs8409.c || {
              echo "FATAL: cs8409.c does not include cirrus_apple.h after patching!"
              echo "Contents of cs8409.c (last 50 lines):"
              tail -50 build/hda/codecs/cirrus/cs8409.c
              exit 1
            }

            echo ""
            echo "=== STEP 5: Build kernel module ==="
            echo "Building in: $(pwd)/build/hda"
            echo "Kernel build dir: ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"

            # Compilar usando make del repo pero con directorio correcto
            make -C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build \
              CFLAGS_MODULE="-DAPPLE_PINSENSE_FIXUP -DAPPLE_CODECS -DCONFIG_SND_HDA_RECONFIG=1 -Wno-unused-variable -Wno-unused-function" \
              M=$(pwd)/build/hda \
              CONFIG_SND_HDA=m \
              modules

            echo ""
            echo "=== Build complete, searching for module ==="
            find build/ -name "*.ko" -type f

          '' else ''
            # ================================================================
            # KERNEL < 6.17 BUILD PROCESS
            # ================================================================
            echo "Pre-6.17 kernel build not yet implemented"
            echo "Please use kernel 6.17 or later"
            exit 1
          ''}

          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall

          echo "=== Looking for compiled module ==="

          # En kernel 6.17+, el modulo se llama snd-hda-codec-cs8409.ko
          # y esta en build/hda/codecs/cirrus/
          MODULE=$(find build/ -name "snd-hda-codec-cs8409.ko" -type f 2>/dev/null | head -1)

          if [ -z "$MODULE" ]; then
            echo "snd-hda-codec-cs8409.ko not found, trying other names..."
            MODULE=$(find build/ -name "*.ko" -type f 2>/dev/null | head -1)
          fi

          if [ -z "$MODULE" ]; then
            echo "ERROR: No .ko module found!"
            echo ""
            echo "Contents of build/hda/codecs/cirrus/:"
            ls -la build/hda/codecs/cirrus/ 2>/dev/null || echo "(directory not found)"
            echo ""
            echo "All .o files:"
            find build/ -name "*.o" -type f 2>/dev/null
            exit 1
          fi

          echo "Found module: $MODULE"

          # Verificar que el modulo tiene el codigo Apple
          if strings "$MODULE" | grep -q "Apple"; then
            echo "[OK] Module contains Apple code"
          else
            echo "[WARN] Module may not contain Apple code - check build logs"
          fi

          # Instalar en updates/ para que tenga prioridad sobre el del kernel
          install -D -m 644 "$MODULE" \
            $out/lib/modules/${kernel.modDirVersion}/updates/snd-hda-codec-cs8409.ko

          echo "Installed to: $out/lib/modules/${kernel.modDirVersion}/updates/snd-hda-codec-cs8409.ko"

          runHook postInstall
        '';

        meta = with lib; {
          description = "Audio driver for MacBooks with Cirrus Logic CS8409 HDA bridge (Apple support)";
          homepage = "https://github.com/davidjo/snd_hda_macbookpro";
          license = licenses.gpl2Only;
          platforms = platforms.linux;
          maintainers = [ ];
        };
      }
    ) { };

in
{
  # ===========================================================================
  # CONFIGURACION DEL MODULO
  # ===========================================================================

  # Incluir el modulo compilado en extraModulePackages
  boot.extraModulePackages = [
    snd-hda-macbookpro
  ];

  # Configuracion de modprobe para audio
  boot.extraModprobeConfig = ''
    # snd-hda-macbookpro: Audio CS8409 para MacBook Pro
    #
    # NOTA: El parametro model= NO aplica al driver CS8409.
    # El driver usa subsystem_id para detectar el modelo automaticamente.
    #
    # Deshabilitamos power_save para evitar pops/clicks al iniciar audio.
    # El audio en MacBook es sensible a cambios de estado del codec.

    options snd-hda-intel power_save=0
    options snd-hda-intel power_save_controller=N

    # position_fix ayuda con sincronizacion en algunos sistemas
    options snd-hda-intel position_fix=1
  '';

  # ===========================================================================
  # SCRIPTS DE DIAGNOSTICO
  # ===========================================================================

  environment.systemPackages = with pkgs; [
    # Script de diagnostico de audio para MacBook Pro
    (writeShellScriptBin "audio-diag" ''
      #!/bin/bash
      echo "=== MACBOOK PRO AUDIO DIAGNOSTICS (CS8409) ==="
      echo ""

      echo "=== 1. KERNEL MODULE ==="
      if lsmod | grep -q snd_hda_codec_cs8409; then
        echo "[OK] snd_hda_codec_cs8409 loaded"
        modinfo snd_hda_codec_cs8409 2>/dev/null | grep -E "^(filename|description)" | head -2
        echo ""
        echo "Module location:"
        modinfo -n snd_hda_codec_cs8409 2>/dev/null
      else
        echo "[FAIL] snd_hda_codec_cs8409 NOT loaded"
        echo "Try: sudo modprobe snd_hda_codec_cs8409"
      fi
      echo ""

      echo "=== 2. CODEC INFO ==="
      if [ -f /proc/asound/card0/codec#0 ]; then
        echo "Codec: $(head -1 /proc/asound/card0/codec#0)"
        echo "Vendor ID: $(cat /sys/class/sound/hwC0D0/vendor_id 2>/dev/null)"
        echo "Subsystem ID: $(cat /sys/class/sound/hwC0D0/subsystem_id 2>/dev/null)"
        echo ""
        echo "GPIO Status (CRITICAL - must show enable=1 for speakers to work):"
        cat /proc/asound/card0/codec#0 | grep -A 10 "^GPIO:"
      else
        echo "[FAIL] Codec info not available"
        echo "No sound card detected"
      fi
      echo ""

      echo "=== 3. EXPECTED GPIO STATE ==="
      echo "For MacBook Pro 13,2 (subsystem 0x106b3600):"
      echo "  GPIO: io=8, o=X, i=0, unsolicited=1, wake=0"
      echo "  IO[0-3]: enable=1, dir=1, data=X (not all 0!)"
      echo ""
      echo "If GPIO shows 'enable=0' for all IO[], the driver is NOT applying"
      echo "Apple quirks. This means you're using the kernel driver instead of"
      echo "the davidjo driver. The kernel driver only supports Dell."
      echo ""

      echo "=== 4. ALSA MIXER CONTROLS ==="
      amixer -c 0 scontrols 2>/dev/null | head -10 || echo "[FAIL] No controls"
      echo ""

      echo "=== 5. PIPEWIRE STATUS ==="
      if systemctl --user is-active pipewire &>/dev/null; then
        echo "[OK] PipeWire running"
        wpctl status 2>/dev/null | grep -A5 "Sinks:" | head -6
      else
        echo "[WARN] PipeWire not running (or running as different user)"
      fi
      echo ""

      echo "=== 6. QUICK TEST ==="
      echo "Test speakers: speaker-test -c 2 -t wav"
      echo "Test headphones: plug in headphones, then speaker-test"
      echo ""

      echo "=== TROUBLESHOOTING ==="
      echo "If GPIO shows all enable=0:"
      echo "  1. Verify snd-hda-macbookpro module is installed in updates/"
      echo "  2. Check: ls /run/current-system/kernel-modules/lib/modules/*/updates/"
      echo "  3. The updates/ module should have priority over kernel module"
      echo ""
      echo "If still not working, the snd-hda-macbookpro module may have"
      echo "failed to compile. Check: sudo nixos-rebuild switch 2>&1 | grep -i error"
    '')
  ];
}
