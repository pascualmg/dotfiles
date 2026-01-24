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
#
# ┌─────────────────────────────────────────────────────────────────────────┐
# │                    GUIA PARA NOOBS DE NIX - FLAKES                      │
# ├─────────────────────────────────────────────────────────────────────────┤
# │                                                                         │
# │  QUE ES UN FLAKE:                                                       │
# │  ────────────────                                                       │
# │  Un flake es como un package.json de Node o Cargo.toml de Rust.         │
# │  Define: dependencias (inputs) y lo que produce (outputs)               │
# │  El archivo flake.lock fija las versiones exactas (reproducibilidad)    │
# │                                                                         │
# │  ESTRUCTURA DE UN FLAKE:                                                │
# │  ───────────────────────                                                │
# │  {                                                                      │
# │    description = "...";         <- Descripcion del proyecto             │
# │    inputs = { ... };            <- Dependencias (repos, otros flakes)   │
# │    outputs = { ... }: { ... };  <- Lo que produce el flake              │
# │  }                                                                      │
# │                                                                         │
# │  INPUTS - De donde vienen los paquetes:                                 │
# │  ──────────────────────────────────────                                 │
# │  nixpkgs.url = "github:NixOS/nixpkgs/...";  <- Repo de paquetes         │
# │  inputs.nixpkgs.follows = "nixpkgs";        <- Usa la misma version     │
# │  flake = false;                             <- No es un flake (raw)     │
# │                                                                         │
# │  OUTPUTS - Lo que produce:                                              │
# │  ─────────────────────────                                              │
# │  nixosConfigurations.hostname   <- Config NixOS para "hostname"         │
# │  homeConfigurations.user        <- Config home-manager para "user"      │
# │  devShells.system.default       <- Shell de desarrollo                  │
# │                                                                         │
# │  FUNCION outputs:                                                       │
# │  ────────────────                                                       │
# │  outputs = { self, nixpkgs, ... }@inputs:                               │
# │            ^^^^^^^^^^^^^^^^^^^^^^^                                      │
# │            Recibe todos los inputs como argumentos                      │
# │            @inputs captura todo en una variable                         │
# │                                                                         │
# │  let ... in:                                                            │
# │  ───────────                                                            │
# │  Dentro de outputs usamos let para definir funciones helper             │
# │  como mkSystem que crea configuraciones NixOS                           │
# │                                                                         │
# └─────────────────────────────────────────────────────────────────────────┘

{

  description = "NixOS configurations for aurin, vespino, and macbook";

  # ---------------------------------------------------------------------------
  # INPUTS - Fuentes de paquetes y modulos
  # ---------------------------------------------------------------------------
  # Cada input es una dependencia externa que el flake necesita.
  # El formato es: nombre.url = "tipo:ubicacion/version";
  # Tipos comunes: github:, path:, git:
  inputs = {
    # Nixpkgs unstable - paquetes mas recientes
    # Todas las maquinas usan unstable para consistencia
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Nixpkgs master - para paquetes bleeding-edge (claude-code, etc)
    # Usar con pkgsMaster.paquete en los modulos
    nixpkgs-master.url = "github:NixOS/nixpkgs/master";

    # Home Manager - gestion de configuracion de usuario
    # "inputs.nixpkgs.follows" significa: usa el mismo nixpkgs que yo
    # Esto evita tener dos versiones de nixpkgs en el sistema
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NixOS Hardware - perfiles hardware especificos
    # Contiene configuraciones para muchos laptops, GPUs, etc.
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # Alacritty themes - repo oficial de temas
    # flake = false significa: no es un flake, solo descarga el repo
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
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Charmbracelet NUR (crush con licencia unfree)
    charm-nur.url = "github:charmbracelet/nur";
  };

  # ---------------------------------------------------------------------------
  # OUTPUTS - Configuraciones NixOS generadas
  # ---------------------------------------------------------------------------
  # La funcion outputs recibe todos los inputs y devuelve un attrset
  # con las configuraciones que queremos generar.
  #
  # { self, nixpkgs, ... }@inputs significa:
  #   - self: referencia a este mismo flake
  #   - nixpkgs: el input llamado nixpkgs
  #   - ...: otros inputs que no nombramos explicitamente
  #   - @inputs: captura TODOS los inputs en la variable "inputs"
  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-master,
      home-manager,
      nixos-hardware,
      alacritty-themes,
      nix-on-droid,
      nix-index-database,
      ...
    }@inputs:
    let
      # Sistema comun para todas las maquinas x86_64
      system = "x86_64-linux";

      # Importamos nixpkgs con allowUnfree = true
      # Esto permite instalar paquetes propietarios (nvidia, chrome, etc)
      pkgs = import nixpkgs {
        inherit system; # Equivalente a: system = system;
        config.allowUnfree = true;
      };

      # pkgs de master para paquetes bleeding-edge
      # Usar como: pkgsMaster.paquete en cualquier modulo
      pkgsMaster = import nixpkgs-master {
        inherit system;
        config.allowUnfree = true;
      };

      # pkgsMaster para ARM (nix-on-droid en Android)
      pkgsMasterArm = import nixpkgs-master {
        system = "aarch64-linux";
        config.allowUnfree = true;
      };

      # =========================================================================
      # mkSystem - Funcion helper para crear configuraciones NixOS
      # =========================================================================
      # Esta funcion encapsula la logica comun de todas las maquinas.
      # Recibe: hostname, lista de modulos hardware, y extras opcionales.
      #
      # PATRON CLONE-FIRST:
      #   - modules/base/ es comun a TODAS las maquinas
      #   - hardware/ contiene modulos especificos de hardware
      #   - hosts/hostname/ contiene overrides especificos del host
      # =========================================================================
      mkSystem =
        {
          hostname, # Nombre de la maquina (aurin, macbook, vespino)
          hardware ? [ ], # Lista de modulos hardware (opcional, default [])
          extra ? [ ], # Modulos extra (opcional, default [])
        }:
        nixpkgs.lib.nixosSystem {
          inherit system;

          # specialArgs pasa variables a TODOS los modulos
          # Cualquier modulo puede recibir estos como argumentos
          specialArgs = {
            inherit inputs;
            inherit home-manager nixos-hardware;
            inherit alacritty-themes;
            inherit pkgsMaster;
          };

          # Lista de modulos que componen la configuracion
          # El orden importa: los modulos posteriores pueden override anteriores
          modules = [
            # Base comun a todas las maquinas
            ./modules/base

            # Hardware-configuration.nix generado por nixos-generate-config
            ./hosts/${hostname}/hardware-configuration.nix

            # Config especifica del host (overrides, servicios locales)
            ./hosts/${hostname}

            # Establecemos el hostname
            { networking.hostName = hostname; }

            # nix-index-database para command-not-found mejorado
            nix-index-database.nixosModules.nix-index
            {
              # Etiqueta la configuracion con el commit de git
              system.configurationRevision = if self ? rev then self.rev else "dirty";
              system.nixos.label = if self ? shortRev then "flake-${self.shortRev}" else "flake-dirty";
              # Habilita "comma" (ejecutar programas sin instalar: , htop)
              programs.nix-index-database.comma.enable = true;
            }

            # Home Manager integrado en NixOS
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                # Usa los mismos pkgs del sistema (no descarga otra vez)
                useGlobalPkgs = true;
                useUserPackages = true;
                # Variables disponibles en la config de home-manager
                extraSpecialArgs = {
                  inherit inputs pkgsMaster alacritty-themes;
                  hostname = hostname;
                };
                # Configuracion de home-manager para el usuario passh
                users.passh = import ./modules/home-manager;
                # Si hay conflicto con archivo existente, renombralo a .backup
                backupFileExtension = "backup";
              };
            }
          ]
          # ++ concatena listas: modules ++ hardware ++ extra
          ++ hardware
          ++ extra;
        };

      # =========================================================================
      # mkDroid - Crear configuracion nix-on-droid (Android)
      # =========================================================================
      mkDroid =
        {
          hostname,
          extra ? [ ],
        }:
        nix-on-droid.lib.nixOnDroidConfiguration {
          pkgs = import nixpkgs {
            system = "aarch64-linux";
            config.allowUnfree = true;
          };

          extraSpecialArgs = {
            inherit inputs;
            inherit pkgsMasterArm;
            inherit alacritty-themes;
          };

          modules = [
            ./droid/common.nix
            ./droid/${hostname}

            {
              home-manager = {
                useGlobalPkgs = true;
                backupFileExtension = "backup";
                extraSpecialArgs = {
                  inherit inputs;
                  inherit pkgsMasterArm;
                  inherit alacritty-themes;
                  hostname = hostname;
                };
                config = ./modules/home-manager/machines/android.nix;
                sharedModules = [
                  nix-index-database.homeModules.nix-index
                  { programs.nix-index-database.comma.enable = true; }
                ];
              };
            }
          ]
          ++ extra;
        };

      # Fin del bloque "let", ahora el attrset que devuelve outputs
    in
    {
      # -----------------------------------------------------------------------
      # NIXOS CONFIGURATIONS
      # -----------------------------------------------------------------------
      # Cada entrada aqui es una configuracion NixOS completa
      # Se usa con: sudo nixos-rebuild switch --flake .#nombre

      nixosConfigurations = {
        # ---------------------------------------------------------------------
        # AURIN - Workstation de produccion (CRITICO)
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
        vespino = mkSystem {
          hostname = "vespino";
          hardware = [
            ./hardware/nvidia/rtx2060.nix
          ];
        };

        # ---------------------------------------------------------------------
        # MACBOOK - Laptop Apple MacBook Pro 13,2 (2016)
        # ---------------------------------------------------------------------
        macbook = mkSystem {
          hostname = "macbook";
          hardware = [
            # Modulos de nixos-hardware para hardware Apple
            nixos-hardware.nixosModules.apple-macbook-pro
            nixos-hardware.nixosModules.common-pc-ssd
            # Modulos locales para configuracion especifica
            ./hardware/apple/macbook-pro-13-2.nix
            ./hardware/apple/snd-hda-macbookpro.nix
          ];
        };
      };

      # -----------------------------------------------------------------------
      # HOME MANAGER STANDALONE (opcional)
      # -----------------------------------------------------------------------
      # Uso: home-manager switch --flake .#passh
      homeConfigurations = {
        passh = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = {
            inherit inputs;
            inherit pkgsMaster;
            inherit alacritty-themes;
            hostname = "aurin";
          };
          modules = [
            ./modules/home-manager
          ];
        };
      };

      # -----------------------------------------------------------------------
      # NIX-ON-DROID - Android
      # -----------------------------------------------------------------------
      # Uso: nix-on-droid switch --flake ~/dotfiles
      nixOnDroidConfigurations = {
        default = mkDroid { hostname = "android"; };
        android = mkDroid { hostname = "android"; };
      };

      # -----------------------------------------------------------------------
      # DESARROLLO - Shell con herramientas NixOS
      # -----------------------------------------------------------------------
      # Uso: nix develop (dentro del repo)
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          nil # LSP para Nix
          nixd # LSP alternativo
          nixfmt # Formateador
          nixpkgs-fmt # Formateador estilo nixpkgs
          statix # Linter
          deadnix # Detecta codigo muerto
          nix-tree # Visualizar dependencias
        ];

        # Este hook se ejecuta al entrar al shell
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
        '';
      };

      # -----------------------------------------------------------------------
      # TEMPLATES
      # -----------------------------------------------------------------------
      # Uso: nix flake init -t ~/dotfiles#module
      templates.module = {
        path = ./templates/module;
        description = "Template para modulo NixOS";
      };
    };
}
