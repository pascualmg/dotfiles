# =============================================================================
# Dotfiles Flake - Configuracion Multi-Maquina NixOS
# =============================================================================
#
# Este flake integra las 3 maquinas NixOS manteniendo compatibilidad con
# el metodo tradicional (stow + channels).
#
# MAQUINAS:
#   - aurin:   Workstation produccion (Dual Xeon + RTX 5080)
#   - vespino: Servidor secundario (Minecraft, NFS, Ollama)
#   - macbook: Laptop Apple MacBook Pro 13,2 (2016)
#
# USO CON FLAKES:
#   # IMPORTANTE: Requiere --impure mientras las configs usen channels
#   # (Esto es temporal hasta migrar completamente a flakes)
#
#   # Desde el directorio dotfiles
#   sudo nixos-rebuild switch --flake .#aurin --impure
#   sudo nixos-rebuild switch --flake .#vespino --impure
#   sudo nixos-rebuild switch --flake .#macbook --impure
#
#   # Desde cualquier lugar
#   sudo nixos-rebuild switch --flake ~/dotfiles#aurin --impure
#
#   # Desde GitHub (requiere migracion completa a flakes puros)
#   # sudo nixos-rebuild switch --flake github:pascualmg/dotfiles#aurin
#
#   # Solo testear (sin hacer switch)
#   sudo nixos-rebuild test --flake .#aurin --impure
#
#   # Ver que cambiaria (dry-run)
#   sudo nixos-rebuild dry-build --flake .#aurin --impure
#
# USO TRADICIONAL (sigue funcionando igual que siempre):
#   sudo stow -v -t / nixos-aurin
#   sudo nixos-rebuild switch
#
# ACTUALIZAR FLAKE.LOCK:
#   nix flake update              # Actualiza todos los inputs
#   nix flake lock --update-input nixpkgs  # Solo nixpkgs
#
# VERIFICAR:
#   nix flake show                # Mostrar outputs
#   nix flake check --impure      # Verificar (con impure por channels)
#
# =============================================================================
# NOTA SOBRE --impure:
#
# Las configuraciones actuales usan channels para home-manager:
#   imports = [ <home-manager/nixos> ];
#
# Esto requiere --impure porque Nix puro no puede resolver paths como <...>.
#
# PLAN DE MIGRACION (en progreso):
#   Fase 1: Crear modules/home-manager/ con config pura [COMPLETADO]
#   Fase 2: Integrar home-manager en flake [ESTE ARCHIVO]
#   Fase 3: Eliminar <home-manager/nixos> de configuration.nix [PENDIENTE]
#   Fase 4: Entonces se puede usar sin --impure
#
# Por ahora, --impure funciona perfectamente y es seguro.
# =============================================================================

{
  description = "NixOS configurations for aurin, vespino, and macbook";

  # ---------------------------------------------------------------------------
  # INPUTS - Fuentes de paquetes y modulos
  # ---------------------------------------------------------------------------
  inputs = {
    # Nixpkgs unstable - paquetes mas recientes
    # Todas las maquinas usan unstable para consistencia
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Home Manager - gestion de configuracion de usuario
    # Sigue la misma version de nixpkgs
    # AHORA: Se usa activamente via home-manager.nixosModules.home-manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NixOS Hardware - perfiles hardware especificos
    # Usado principalmente por macbook para drivers Apple
    # NOTA: macbook actualmente usa fetchTarball, este input es para migracion futura
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };

  # ---------------------------------------------------------------------------
  # OUTPUTS - Configuraciones NixOS generadas
  # ---------------------------------------------------------------------------
  outputs = { self, nixpkgs, home-manager, nixos-hardware, ... }@inputs:
    let
      # Sistema comun para todas las maquinas
      system = "x86_64-linux";

      # pkgs con unfree habilitado (para home-manager)
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      # -------------------------------------------------------------------------
      # Funcion helper para crear configuraciones NixOS
      # -------------------------------------------------------------------------
      # Reduce repeticion y asegura consistencia
      #
      # Parametros:
      #   hostname: nombre de la maquina
      #   configPath: path al configuration.nix
      #   extraModules: modulos adicionales (opcional)
      #   enableHomeManager: si incluir home-manager del flake (default: false)
      #                      Poner en true cuando se elimine <home-manager/nixos>
      #                      del configuration.nix correspondiente
      # -------------------------------------------------------------------------
      mkNixosConfig = {
        hostname,
        configPath,
        extraModules ? [],
        enableHomeManager ? false
      }:
        nixpkgs.lib.nixosSystem {
          inherit system;

          # specialArgs pasa valores adicionales a todos los modulos
          # Esto permite que los modulos accedan a inputs si lo necesitan
          specialArgs = {
            inherit inputs;
            # Pasar home-manager y nixos-hardware para uso en modulos
            inherit home-manager nixos-hardware;
          };

          modules = [
            # Configuracion principal de la maquina
            configPath

            # Modulo para compatibilidad: registra el flake en el sistema
            {
              # Revision del flake para trazabilidad
              system.configurationRevision =
                if self ? rev
                then self.rev
                else "dirty";

              # Label en el bootloader para identificar builds de flake
              system.nixos.label =
                if self ? shortRev
                then "flake-${self.shortRev}"
                else "flake-dirty";

              # Asegurar que nix tiene flakes habilitados
              nix.settings.experimental-features = [ "nix-command" "flakes" ];
            }
          ]
          # Home Manager del flake (cuando se active)
          ++ (if enableHomeManager then [
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                # Usar pkgs del sistema (no traer otro nixpkgs)
                useGlobalPkgs = true;
                # Instalar paquetes en /etc/profiles en lugar de ~/.nix-profile
                useUserPackages = true;
                # Pasar inputs a home-manager modules
                extraSpecialArgs = { inherit inputs; };
                # Configuracion del usuario passh
                users.passh = import ./modules/home-manager;
                # Permitir paquetes unfree en home-manager
                # (backupFileExtension evita conflictos con archivos existentes)
                backupFileExtension = "backup";
              };
            }
          ] else [])
          ++ extraModules;
        };
    in
    {
      # -----------------------------------------------------------------------
      # NIXOS CONFIGURATIONS
      # -----------------------------------------------------------------------

      nixosConfigurations = {
        # ---------------------------------------------------------------------
        # AURIN - Workstation de produccion (CRITICO)
        # ---------------------------------------------------------------------
        # Hardware: Dual Xeon E5-2699v3, 128GB RAM, RTX 5080
        # Rol: Desarrollo, streaming (Sunshine), VMs
        #
        # ADVERTENCIA: Sistema de produccion
        # Testear cambios en vespino primero cuando sea posible
        #
        # Uso:
        #   sudo nixos-rebuild test --flake ~/dotfiles#aurin --impure
        #   sudo nixos-rebuild switch --flake ~/dotfiles#aurin --impure
        #
        # ESTADO HOME-MANAGER:
        #   enableHomeManager = false (por ahora)
        #   configuration.nix todavia usa <home-manager/nixos>
        #   Cambiar a true cuando se elimine el import del channel
        # ---------------------------------------------------------------------
        aurin = mkNixosConfig {
          hostname = "aurin";
          configPath = ./nixos-aurin/etc/nixos/configuration.nix;
          enableHomeManager = false;  # TODO: cambiar a true en Fase 3
        };

        # ---------------------------------------------------------------------
        # AURIN-PURE - Version experimental sin channels
        # ---------------------------------------------------------------------
        # EXPERIMENTAL: Esta configuracion usa home-manager del flake
        # en lugar del channel. Usar para testing antes de migrar aurin.
        #
        # FASE 3: Configuracion lista con:
        #   - configuration-pure.nix (sin <home-manager/nixos>)
        #   - Home Manager integrado via flake
        #   - NO requiere --impure
        #
        # Uso:
        #   sudo nixos-rebuild test --flake ~/dotfiles#aurin-pure
        #   (sin --impure!)
        # ---------------------------------------------------------------------
        aurin-pure = mkNixosConfig {
          hostname = "aurin";
          configPath = ./nixos-aurin/etc/nixos/configuration-pure.nix;
          enableHomeManager = true;
        };

        # ---------------------------------------------------------------------
        # VESPINO - Servidor secundario / Testing
        # ---------------------------------------------------------------------
        # Hardware: PC antiguo con NVIDIA
        # Rol: Minecraft server, NFS, Ollama, VM VPN Vocento
        #
        # Usar como banco de pruebas antes de aplicar cambios a aurin
        #
        # Uso:
        #   sudo nixos-rebuild test --flake ~/dotfiles#vespino --impure
        #   sudo nixos-rebuild switch --flake ~/dotfiles#vespino --impure
        #
        # ESTADO HOME-MANAGER:
        #   enableHomeManager = false (por ahora)
        #   configuration.nix todavia usa <home-manager/nixos>
        # ---------------------------------------------------------------------
        vespino = mkNixosConfig {
          hostname = "vespino";
          configPath = ./nixos-vespino/etc/nixos/configuration.nix;
          enableHomeManager = false;  # TODO: cambiar a true en Fase 3
        };

        # ---------------------------------------------------------------------
        # MACBOOK - Laptop Apple MacBook Pro 13,2 (2016)
        # ---------------------------------------------------------------------
        # Hardware: MacBook Pro 13" 2016 con Touch Bar
        # - CPU: Intel Core i5/i7 Skylake
        # - Display: Retina 2560x1600 (227 DPI)
        # - GPU: Intel Iris Graphics 550
        # - WiFi: Broadcom BCM43602
        # - Touch Bar: OLED con T1 chip
        #
        # Instalacion: USB 128GB (testing)
        # Desktop: XMonad (compartido con aurin)
        #
        # PURE FLAKE desde dia 1:
        #   - Home Manager integrado
        #   - nixos-hardware para Apple
        #   - NO requiere --impure
        #
        # Uso:
        #   sudo nixos-rebuild switch --flake ~/dotfiles#macbook
        # ---------------------------------------------------------------------
        macbook = mkNixosConfig {
          hostname = "macbook";
          configPath = ./nixos-macbook/etc/nixos/configuration-pure.nix;
          enableHomeManager = true;
          # nixos-hardware para MacBook Pro
          extraModules = [
            nixos-hardware.nixosModules.apple-macbook-pro-13-2
          ];
        };
      };

      # -----------------------------------------------------------------------
      # HOME MANAGER STANDALONE (opcional)
      # -----------------------------------------------------------------------
      # Permite usar home-manager independiente del sistema NixOS
      # Util para: testing, maquinas no-NixOS, o preferencia personal
      #
      # Uso:
      #   nix run ~/dotfiles#homeConfigurations.passh.activationPackage
      #   # o si tienes home-manager instalado:
      #   home-manager switch --flake ~/dotfiles#passh
      # -----------------------------------------------------------------------
      homeConfigurations = {
        passh = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = { inherit inputs; };
          modules = [
            ./modules/home-manager
          ];
        };
      };

      # -----------------------------------------------------------------------
      # DESARROLLO - Shells y herramientas
      # -----------------------------------------------------------------------

      # Shell de desarrollo con herramientas NixOS
      # Uso: nix develop (o: nix develop ~/dotfiles)
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          # LSP para Nix (elegir uno)
          nil        # Mas ligero, basico
          nixd       # Mas features, usa evaluacion real

          # Formateadores
          nixfmt-classic # Estilo clasico
          nixpkgs-fmt    # Estilo nixpkgs

          # Linters
          statix     # Sugerencias de mejora
          deadnix    # Detecta codigo muerto

          # Otros
          nix-tree   # Visualizar dependencias
        ];

        shellHook = ''
          echo "=========================================="
          echo "  NixOS Dotfiles Development Shell"
          echo "=========================================="
          echo ""
          echo "Comandos flake:"
          echo "  nix flake show           - Mostrar outputs"
          echo "  nix flake check --impure - Verificar sintaxis"
          echo "  nix flake update         - Actualizar lock"
          echo ""
          echo "Rebuild NixOS (requiere --impure por ahora):"
          echo "  sudo nixos-rebuild test --flake .#aurin --impure"
          echo "  sudo nixos-rebuild switch --flake .#vespino --impure"
          echo ""
          echo "Home Manager standalone:"
          echo "  home-manager switch --flake .#passh"
          echo ""
          echo "Metodo tradicional (sigue funcionando):"
          echo "  sudo stow -t / nixos-aurin && sudo nixos-rebuild switch"
          echo ""
        '';
      };

      # -----------------------------------------------------------------------
      # TEMPLATES (opcional, para referencia)
      # -----------------------------------------------------------------------

      # Template para crear nuevo modulo NixOS
      # Uso: nix flake init -t ~/dotfiles#module
      templates.module = {
        path = ./templates/module;
        description = "Template para modulo NixOS";
      };
    };
}
