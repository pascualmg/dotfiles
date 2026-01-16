# =============================================================================
# Core Home Manager Configuration
# =============================================================================
# Configuracion MINIMA que funciona en CUALQUIER sistema:
# - NixOS desktop (aurin, macbook, vespino)
# - Nix-on-Droid (android)
# - Cualquier sistema con home-manager standalone
#
# REGLA: Solo incluir cosas que NO requieran:
# - X11/Wayland (nada de GUI)
# - Servicios systemd de usuario (no existen en Android)
# - Paquetes pesados o que no compilen en aarch64
#
# Para config de desktop, ver passh.nix que importa este core.
# =============================================================================

{ config, pkgs, lib, ... }:

{
  # Home Manager basico
  programs.home-manager.enable = true;

  home = {
    stateVersion = "24.05";
    # mkDefault permite que nix-on-droid override con "nix-on-droid"
    username = lib.mkDefault "passh";
    homeDirectory = lib.mkDefault "/home/passh";

    # =========================================================================
    # PAQUETES CORE - CLI que funciona en todos lados
    # =========================================================================
    packages = with pkgs; [
      # Core utils
      git
      gh
      ripgrep
      fd
      wget
      curl
      neovim
      tree
      unzip
      zip
      gzip
      file
      eza
      direnv
      jq
      bat
      htop
      btop

      # Shells
      fish

      # Development basics
      gnumake
      gcc

      # Formatters/Linters CLI
      nixfmt
      shfmt
      shellcheck

      # Network tools
      openssh
      dig
    ];

    sessionVariables = {
      # mkDefault permite que emacs.nix override esto en desktop
      EDITOR = lib.mkDefault "nvim";
      VISUAL = lib.mkDefault "nvim";
      ORG_DIRECTORY = "$HOME/org";
      ORG_ROAM_DIRECTORY = "$HOME/org/roam";
    };

    # Crear directorios basicos
    activation.createCoreDirectories = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      echo "Creando estructura de directorios core..."
      mkdir -p $HOME/org/roam
      mkdir -p $HOME/src
      mkdir -p $HOME/.ssh
      chmod 700 $HOME/.ssh
    '';
  };

  # =========================================================================
  # GIT CONFIG - Comun a todas las maquinas
  # =========================================================================
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Pascual Munoz Galian";
        email = "pmunozg@ces.vocento.com";
      };
      init.defaultBranch = "main";
      pull.rebase = false;
      color.ui = "auto";
      credential.helper = "store";
    };
    ignores = [
      ".org-id-locations"
      "*.org~"
      ".org-roam.db"
      ".DS_Store"
      ".idea"
      "*~"
      "\\#*\\#"
    ];
  };

  # =========================================================================
  # SSH CONFIG BASE
  # =========================================================================
  # Crear config SSH con permisos correctos
  home.activation.createSshConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    rm -f ~/.ssh/config 2>/dev/null || true
    cat > ~/.ssh/config << 'SSHEOF'
Host *
  AddKeysToAgent yes
  ServerAliveInterval 30
  ServerAliveCountMax 5
  TCPKeepAlive yes

Host aurin
  HostName campo.zapto.org
  Port 2222
  User passh
  ControlMaster auto
  ControlPath ~/.ssh/sockets/%r@%h-%p
  ControlPersist 600
SSHEOF
    mkdir -p ~/.ssh/sockets
    chmod 700 ~/.ssh/sockets
    chmod 600 ~/.ssh/config
  '';
}
