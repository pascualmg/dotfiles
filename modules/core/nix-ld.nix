# =============================================================================
# MODULO COMPARTIDO: nix-ld (Ejecutar binarios dinámicos en NixOS)
# =============================================================================
#
# NixOS no puede ejecutar binarios Linux genéricos "out of the box" porque:
#   - No tiene /lib, /lib64, /usr/lib (rutas estándar FHS)
#   - Los binarios dinámicos buscan el linker en /lib64/ld-linux-x86-64.so.2
#   - NixOS usa rutas únicas en /nix/store/
#
# nix-ld soluciona esto creando un "shim" que redirige las llamadas del linker
# a las librerías correctas del nix store.
#
# CASOS DE USO:
#   - JetBrains Gateway / IntelliJ Remote Development
#   - VSCode Remote SSH
#   - Binarios descargados por npm, cargo, pip, etc.
#   - AppImages
#   - Cualquier ejecutable Linux no empaquetado en nixpkgs
#
# USO:
#   imports = [ ../modules/common/nix-ld.nix ];
#
# REFERENCIA:
#   - https://github.com/Mic92/nix-ld
#   - https://nix.dev/permalink/stub-ld
#
# =============================================================================

{ config, pkgs, lib, ... }:

{
  programs.nix-ld = {
    enable = true;

    # Librerías comunes que necesitan la mayoría de binarios dinámicos
    # Especialmente orientado a IDEs de JetBrains y herramientas de desarrollo
    libraries = with pkgs; [
      # === BÁSICAS (casi todo las necesita) ===
      stdenv.cc.cc.lib    # libstdc++, libgcc_s
      zlib                # Compresión (muy común)
      glib                # GLib (GTK apps, muchas herramientas)

      # === GRÁFICAS (IDEs, apps con UI) ===
      libGL               # OpenGL
      libxkbcommon        # Keyboard handling

      # === FUENTES (IDEs, editores) ===
      freetype            # Renderizado de fuentes
      fontconfig          # Configuración de fuentes

      # === X11 (apps gráficas en X) ===
      xorg.libX11         # X11 base
      xorg.libXext        # Extensiones X11
      xorg.libXrender     # Renderizado X11
      xorg.libXi          # Input devices
      xorg.libXtst        # Testing/automation
      xorg.libXcursor     # Cursores
      xorg.libXrandr      # Resolución/pantallas

      # === EXTRAS (herramientas varias) ===
      openssl             # SSL/TLS (curl, wget internos)
      curl                # Muchos binarios usan libcurl
      expat               # XML parsing
      libffi              # Foreign function interface
      util-linux          # libuuid, libblkid
    ];
  };
}
