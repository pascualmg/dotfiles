# =============================================================================
# Dotfiles Flake - Configuracion Multi-Maquina NixOS
# =============================================================================
#
# Arquitectura "Clone-First": Todas las maquinas son CLONES IDENTICOS.
# Solo cambia: hostname, hardware-configuration.nix, y modulos hardware.
#
# MAQUINAS:
#   - aurin:   Workstation (Dual Xeon E5-2699v3 + RTX 5080)
#   - vespino: Servidor (AMD + RTX 2060, Minecraft, NFS)
#   - macbook: Laptop (MacBook Pro 13,2 2016)
#   - android: Movil (Nix-on-Droid, aarch64)
#
# USO:
#   sudo nixos-rebuild switch --flake ~/dotfiles#aurin --impure
#   sudo nixos-rebuild switch --flake ~/dotfiles#vespino --impure
#   sudo nixos-rebuild switch --flake ~/dotfiles#macbook
#   nix-on-droid switch --flake ~/dotfiles  # Android
#
# NOTA: --impure necesario en aurin/vespino para leer hosts Vocento
#
# FLAKE COMMANDS:
#   nix flake show      # Mostrar outputs
#   nix flake check     # Verificar sintaxis
#   nix flake update    # Actualizar lock
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

    # Alacritty themes - repo oficial de temas para hot-reload
    alacritty-themes = {
      url = "github:alacritty/alacritty-theme";
      flake = false;
    };

    # Nix-on-Droid - Nix en Android
    # Permite usar el mismo flake en el movil
    nix-on-droid = {
      url = "github:nix-community/nix-on-droid/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # nix-index-database - Base de datos precompilada para nix-index
    # Proporciona command-not-found mejorado sin necesidad de generar indice
    # Se actualiza semanalmente automaticamente
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # ---------------------------------------------------------------------------
  # OUTPUTS - Configuraciones NixOS generadas
  # ---------------------------------------------------------------------------
  outputs = { self, nixpkgs, nixpkgs-master, home-manager, nixos-hardware, alacritty-themes, nix-on-droid, nix-index-database, ... }@inputs:
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

      # pkgsMaster para ARM (nix-on-droid)
      pkgsMasterArm = import nixpkgs-master {
        system = "aarch64-linux";
        config.allowUnfree = true;
      };

      # =========================================================================
      # mkSystem - Crear configuracion NixOS (Clone-First)
      # =========================================================================
      # Todas las maquinas comparten modules/base/ y solo diferencian hardware.
      # =========================================================================
      mkSystem = {
        hostname,
        hardware ? [],
        extra ? [],  # Modulos adicionales opt-in (ej: vocento-vpn.nix)
      }: nixpkgs.lib.nixosSystem {
        inherit system;

        specialArgs = {
          inherit inputs;
          inherit home-manager nixos-hardware;
          inherit alacritty-themes;
          inherit pkgsMaster;
        };

        modules = [
          # ===== BASE UNIFICADA (igual para TODAS las maquinas) =====
          ./modules/base

          # ===== HOST SPECIFIC =====
          ./hosts/${hostname}/hardware-configuration.nix
          ./hosts/${hostname}

          # ===== HOSTNAME =====
          { networking.hostName = hostname; }

          # ===== NIX-INDEX DATABASE =====
          nix-index-database.nixosModules.nix-index
          {
            system.configurationRevision =
              if self ? rev then self.rev else "dirty";
            system.nixos.label =
              if self ? shortRev then "flake-${self.shortRev}" else "flake-dirty";
            programs.nix-index-database.comma.enable = true;
          }

          # ===== HOME MANAGER =====
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = {
                inherit inputs pkgsMaster alacritty-themes;
                hostname = hostname;
              };
              users.passh = import ./modules/home-manager;
              backupFileExtension = "backup";
            };
          }
        ] ++ hardware ++ extra;
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
        # ARQUITECTURA CLONE-FIRST (migrado 2026-01-19)
        # Hardware: Dual Xeon E5-2699v3 + RTX 5080 + FiiO K7
        # Rol: Desarrollo, streaming (Sunshine), VMs
        #
        # Uso:
        #   sudo nixos-rebuild switch --flake ~/dotfiles#aurin --impure
        #
        # NOTA: --impure necesario para leer /home/passh/src/vocento/autoenv/hosts_all.txt
        # ---------------------------------------------------------------------
        aurin = mkSystem {
          hostname = "aurin";
          hardware = [
            ./hardware/nvidia/rtx5080.nix
            ./hardware/audio/fiio-k7.nix
          ];
        };

        # ---------------------------------------------------------------------
        # VESPINO - Servidor secundario / Testing
        # ---------------------------------------------------------------------
        # ARQUITECTURA CLONE-FIRST (migrado 2026-01-19)
        # Hardware: AMD CPU + NVIDIA RTX 2060
        # Rol: Minecraft server, NFS, Ollama, VM VPN Vocento
        #
        # Uso:
        #   sudo nixos-rebuild switch --flake ~/dotfiles#vespino --impure
        # ---------------------------------------------------------------------
        vespino = mkSystem {
          hostname = "vespino";
          hardware = [
            ./hardware/nvidia/rtx2060.nix
          ];
        };

        # ---------------------------------------------------------------------
        # MACBOOK - Laptop Apple MacBook Pro 13,2 (2016)
        # ---------------------------------------------------------------------
        # ARQUITECTURA CLONE-FIRST (migrado 2026-01-18)
        # Usa modules/base/ + hardware/ + hosts/
        #
        # Uso:
        #   sudo nixos-rebuild switch --flake ~/dotfiles#macbook
        # ---------------------------------------------------------------------
        macbook = mkSystem {
          hostname = "macbook";
          hardware = [
            nixos-hardware.nixosModules.apple-macbook-pro
            nixos-hardware.nixosModules.common-pc-ssd
            ./hardware/apple/macbook-pro-13-2.nix
            ./hardware/apple/snd-hda-macbookpro.nix
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
            inherit alacritty-themes;  # Temas para hot-reload
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
        extraSpecialArgs = {
          inherit pkgsMasterArm;
        };
        modules = [
          ./nix-on-droid/nix-on-droid.nix
          {
            home-manager = {
              useGlobalPkgs = true;
              backupFileExtension = "backup";
              extraSpecialArgs = {
                inherit inputs;
                inherit pkgsMasterArm;
                inherit alacritty-themes;
                hostname = "android";  # Mismo patron que desktop
              };
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
