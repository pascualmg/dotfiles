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
#   - android: Movil con Nix-on-Droid (aarch64)
#
# USO CON FLAKES:
#   # Desde el directorio dotfiles
#   sudo nixos-rebuild switch --flake .#aurin
#   sudo nixos-rebuild switch --flake .#vespino --impure  # vespino aun usa channels
#   sudo nixos-rebuild switch --flake .#macbook
#
#   # Desde cualquier lugar
#   sudo nixos-rebuild switch --flake ~/dotfiles#aurin
#
#   # Solo testear (sin hacer switch)
#   sudo nixos-rebuild test --flake .#aurin
#
#   # Ver que cambiaria (dry-run)
#   sudo nixos-rebuild dry-build --flake .#aurin
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
# NOTA SOBRE MIGRACION:
#
# aurin y macbook usan home-manager integrado en el flake (NO requieren --impure)
# vespino aun usa <home-manager/nixos> channel (requiere --impure)
#
# ESTADO:
#   aurin:   ✅ Migrado (configuration-pure.nix + enableHomeManager=true)
#   macbook: ✅ Migrado
#   vespino: ⏳ Pendiente de migracion
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

    # Nixpkgs master - para paquetes bleeding-edge (claude-code, etc)
    # Usar con pkgsMaster.paquete en los modulos
    nixpkgs-master.url = "github:NixOS/nixpkgs/master";

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

    # Nix-on-Droid - Nix en Android
    # Permite usar el mismo flake en el movil
    nix-on-droid = {
      url = "github:nix-community/nix-on-droid/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  # ---------------------------------------------------------------------------
  # OUTPUTS - Configuraciones NixOS generadas
  # ---------------------------------------------------------------------------
  outputs = { self, nixpkgs, nixpkgs-master, home-manager, nixos-hardware, nix-on-droid, ... }@inputs:
    let
      # Sistema comun para todas las maquinas
      system = "x86_64-linux";

      # pkgs con unfree habilitado (para home-manager)
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      # pkgs de master para paquetes bleeding-edge (claude-code, etc)
      # Usar como: pkgsMaster.claude-code en cualquier modulo
      pkgsMaster = import nixpkgs-master {
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
            # pkgsMaster para paquetes bleeding-edge
            inherit pkgsMaster;
          };

          modules = [
            # Configuracion principal de la maquina
            configPath

            # MODULOS COMUNES - compartidos por todas las maquinas
            ./modules/common/packages.nix
            ./modules/common/services.nix

            # DESKTOP WAYLAND - Hyprland y niri (habilitados por defecto)
            ./modules/desktop/hyprland.nix
            ./modules/desktop/niri.nix

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
                # Pasar inputs Y hostname a home-manager modules
                extraSpecialArgs = {
                  inherit inputs;
                  inherit pkgsMaster;  # Para paquetes bleeding-edge
                  hostname = hostname;  # permite configs por maquina
                };
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
        #   sudo nixos-rebuild switch --flake ~/dotfiles#aurin --impure
        #
        # NOTA: --impure necesario para leer /home/passh/src/vocento/autoenv/hosts_all.txt
        # Sin --impure, los hosts de desarrollo Vocento no se incluyen en /etc/hosts
        #
        # Home Manager integrado via flake (configuration-pure.nix)
        # ---------------------------------------------------------------------
        aurin = mkNixosConfig {
          hostname = "aurin";
          configPath = ./nixos-aurin/etc/nixos/configuration.nix;
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
          enableHomeManager = true;
        };

        # ---------------------------------------------------------------------
        # MACBOOK - Laptop Apple MacBook Pro 13,2 (2016)
        # ---------------------------------------------------------------------
        # Hardware: Intel Skylake, Touch Bar, SSD externo Thunderbolt
        # Rol: Uso movil, desarrollo ligero
        #
        # Uso:
        #   sudo nixos-rebuild switch --flake ~/dotfiles#macbook
        # ---------------------------------------------------------------------
        macbook = mkNixosConfig {
          hostname = "macbook";
          configPath = ./nixos-macbook/etc/nixos/configuration.nix;
          enableHomeManager = true;
          extraModules = [
            nixos-hardware.nixosModules.apple-macbook-pro
            nixos-hardware.nixosModules.common-pc-ssd
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
          extraSpecialArgs = {
            inherit inputs;
            inherit pkgsMaster;  # Para paquetes bleeding-edge
            hostname = "aurin";  # Default para standalone
          };
          modules = [
            ./modules/home-manager
          ];
        };
      };

      # -----------------------------------------------------------------------
      # NIX-ON-DROID - Android
      # -----------------------------------------------------------------------
      # Configuracion para el movil con Nix-on-Droid.
      # Usa el mismo flake que el resto de maquinas, compartiendo core.nix.
      #
      # Instalacion inicial en Android:
      #   1. Instalar Nix-on-Droid desde F-Droid o GitHub releases
      #   2. Clonar dotfiles: git clone <repo> ~/dotfiles
      #   3. nix-on-droid switch --flake ~/dotfiles
      #
      # Actualizaciones posteriores:
      #   nix-on-droid switch --flake ~/dotfiles
      # -----------------------------------------------------------------------
      nixOnDroidConfigurations.default = nix-on-droid.lib.nixOnDroidConfiguration {
        pkgs = import nixpkgs { system = "aarch64-linux"; };
        modules = [
          ./nix-on-droid/nix-on-droid.nix
          {
            home-manager = {
              useGlobalPkgs = true;
              backupFileExtension = "backup";
              config = ./modules/home-manager/machines/android.nix;
            };
          }
        ];
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
          nixfmt # Estilo clasico
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
          echo "  nix flake check          - Verificar sintaxis"
          echo "  nix flake update         - Actualizar lock"
          echo ""
          echo "Rebuild NixOS:"
          echo "  sudo nixos-rebuild switch --flake .#aurin --impure"
          echo "  sudo nixos-rebuild switch --flake .#macbook"
          echo "  sudo nixos-rebuild switch --flake .#vespino --impure"
          echo ""
          echo "Home Manager standalone:"
          echo "  home-manager switch --flake .#passh"
          echo ""
          echo "Nix-on-Droid (Android):"
          echo "  nix-on-droid switch --flake ~/dotfiles"
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
