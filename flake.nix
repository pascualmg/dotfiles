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
# PLAN DE MIGRACION (futuro):
#   1. Eliminar <home-manager/nixos> de cada configuration.nix
#   2. Eliminar fetchTarball de nixos-hardware en macbook
#   3. Quitar los imports via channels de las configs
#   4. Entonces se puede usar sin --impure
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
    # NOTA: Por ahora las configs lo importan via channels, no via este input
    # Cuando se migre completamente, se usara este input
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

      # Funcion helper para crear configuraciones NixOS
      # Reduce repeticion y asegura consistencia
      mkNixosConfig = { hostname, configPath, extraModules ? [] }:
        nixpkgs.lib.nixosSystem {
          inherit system;

          # specialArgs pasa valores adicionales a todos los modulos
          # Esto permite que los modulos accedan a inputs si lo necesitan
          specialArgs = {
            inherit inputs;
            # Pasar home-manager y nixos-hardware para uso futuro en modulos
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
          ] ++ extraModules;
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
        # ---------------------------------------------------------------------
        aurin = mkNixosConfig {
          hostname = "aurin";
          configPath = ./nixos-aurin/etc/nixos/configuration.nix;
          # No extraModules - home-manager viene via channels en config
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
        # ---------------------------------------------------------------------
        vespino = mkNixosConfig {
          hostname = "vespino";
          configPath = ./nixos-vespino/etc/nixos/configuration.nix;
          # No extraModules - home-manager viene via channels en config
        };

        # ---------------------------------------------------------------------
        # MACBOOK - Laptop Apple MacBook Pro 13,2 (2016)
        # ---------------------------------------------------------------------
        # COMMENTED OUT: Configuracion generada pero no instalada todavia
        # Hardware: Intel Skylake, Touch Bar, SSD externo Thunderbolt
        # Rol: Uso movil, desarrollo ligero
        #
        # Descomentar cuando se instale NixOS en el MacBook
        #
        # macbook = mkNixosConfig {
        #   hostname = "macbook";
        #   configPath = ./nixos-macbook/etc/nixos/configuration.nix;
        # };
      };

      # -----------------------------------------------------------------------
      # DESARROLLO - Shells y herramientas
      # -----------------------------------------------------------------------

      # Shell de desarrollo con herramientas NixOS
      # Uso: nix develop (o: nix develop ~/dotfiles)
      devShells.${system}.default = nixpkgs.legacyPackages.${system}.mkShell {
        buildInputs = with nixpkgs.legacyPackages.${system}; [
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
          echo "Rebuild (requiere --impure por ahora):"
          echo "  sudo nixos-rebuild test --flake .#aurin --impure"
          echo "  sudo nixos-rebuild switch --flake .#vespino --impure"
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
