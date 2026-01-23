# =============================================================================
# Crush AI Agent (Charmbracelet) - NUR Package
# =============================================================================
# Clone-first: Config symlinked from ~/dotfiles/crush/
#
# CONFIG (managed):
#   - crush.json (providers, models)
#
# Crush can use any provider: Ollama, Anthropic, OpenAI, etc.
# Config is shared across machines, edit ~/dotfiles/crush/.config/crush/crush.json
#
# PACKAGE SOURCE:
#   - NUR Charmbracelet (github:charmbracelet/nur)
#   - Version: 0.35.0+ (latest from NUR vs 0.22.1 in nixpkgs)
#   - License: fsl11Mit (unfree) - manejado via fetchGit + callPackage
#
# WHY THIS APPROACH WORKS:
#   1. fetchGit descarga NUR sin añadirlo al flake
#   2. pkgs.callPackage rebuilda crush usando NUESTRO pkgs
#   3. Nuestro pkgs tiene allowUnfree = true (definido en flake.nix)
#   4. Por tanto crush hereda allowUnfree y se puede instalar
#   5. No requiere modificar flake.nix ni overlays
#   6. Clone-first: funciona igual en todas las máquinas
#
# ALTERNATIVE REJECTED:
#   - Añadir charm-nur al flake → complicado (overlays, specialArgs, etc.)
#   - Usar pkgs.crush (nixpkgs) → versión antigua (0.22.1)
#   - NIXPKGS_ALLOW_UNFREE=1 → no es declarativo
#
# LESSONS LEARNED:
#   - fetchGit + callPackage es la solución simple para NUR packages
#   - No todo tiene que ir en el flake
#   - A veces la solución más simple es la correcta
# =============================================================================

{
  config,
  lib,
  pkgs,
  ...
}:

let
  homeDir = config.home.homeDirectory;
  dotfilesDir = "${homeDir}/dotfiles";

  # Fetch NUR Charmbracelet (no requiere añadirlo al flake)
  charm-nur = builtins.fetchGit {
    url = "https://github.com/charmbracelet/nur";
    ref = "master";
  };

  # Rebuild crush con NUESTRO pkgs (hereda allowUnfree = true del flake.nix)
  # Esto permite instalar packages con licencias unfree sin modificar el flake
  crush = pkgs.callPackage "${charm-nur}/pkgs/crush" { };
in

{
  # ===========================================================================
  # Install Crush package (from NUR Charmbracelet)
  # ===========================================================================

  home.packages = [
    crush # NUR 0.35.0+ (rebuildeado con nuestro pkgs)
  ];

  # ===========================================================================
  # Configuration symlink
  # ===========================================================================
  # Using activation script because xdg.configFile doesn't respect mkOutOfStoreSymlink

  home.activation.setupCrush = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    echo "📁 Configurando crush..."

    # Create config directory
    mkdir -p ~/.config/crush

    # Remove nix store symlink if exists
    if [[ -L ~/.config/crush/crush.json ]] && [[ "$(readlink ~/.config/crush/crush.json)" == *"/nix/store/"* ]]; then
      echo "🧹 Limpiando symlink de nix store..."
      rm ~/.config/crush/crush.json
    fi

    # Create symlink to dotfiles (editable, not in store)
    if [[ ! -e ~/.config/crush/crush.json ]]; then
      echo "🔗 Creando symlink: crush.json -> dotfiles"
      ln -sf "${dotfilesDir}/crush/.config/crush/crush.json" ~/.config/crush/crush.json
    fi
  '';
}
