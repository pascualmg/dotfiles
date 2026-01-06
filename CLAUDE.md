# Dotfiles - Instrucciones para Claude

## Contexto del proyecto

Este es el repositorio de dotfiles de passh@aurin usando GNU Stow para gestión de enlaces simbólicos.

## Configuraciones principales

- **home-manager/**: Gestión de paquetes con Nix Home Manager
- **nixos-aurin/**: Configuración NixOS específica de Aurin (ver nixos-aurin/README.org)
- **xmonad/**: Window manager (XMonad + Haskell)
- **picom/**: Compositor X11
- **fish/**: Shell principal
- **alacritty/**: Terminal emulator

Ver **README.org** para documentación completa.

## Historia importante: Limpieza de wallpapers (2025-11-22)

El repo tenía 880MB en `.git/` debido a 219 wallpapers AI (785MB) versionados en git.

**Solución aplicada:**
1. Wallpapers removidos del tracking git (añadidos a .gitignore)
2. Historial git reescrito con `git filter-branch`
3. Repo compactado con `git gc --aggressive`
4. **Resultado**: .git/ reducido de 880MB a 98MB

**IMPORTANTE**: El historial fue reescrito y pusheado con `--force` al origin.

## Si clonas este repo en otra máquina y ves problemas

Si al clonar encuentras que el repo es muy grande (>500MB) o hay conflictos con wallpapers:

```bash
cd ~/dotfiles

# Opción 1: Forzar actualización (recomendado)
git fetch origin
git reset --hard origin/master
git clean -fdx

# Opción 2: Re-clonar desde cero (más seguro)
cd ~
mv dotfiles dotfiles.backup
git clone <repo-url> dotfiles
```

**Nota**: Los wallpapers (785MB) NO están en git, solo locales en aurin:/home/passh/dotfiles/wallpapers/

## Aplicar configuraciones (FLAKES)

**IMPORTANTE**: Este repo usa NixOS Flakes. Home-manager está integrado en NixOS, NO es un comando separado.

```bash
# Aurin - SIEMPRE usar --impure (necesario para hosts Vocento)
sudo nixos-rebuild switch --flake ~/dotfiles#aurin --impure

# Macbook
sudo nixos-rebuild switch --flake ~/dotfiles#macbook

# Actualizar flake.lock
nix flake update
```

**NO usar** `home-manager switch` - no existe como comando separado, está integrado en nixos-rebuild.

### Stow (solo para configs NO migradas a home-manager)

```bash
cd ~/dotfiles
stow -v xmonad   # XMonad aún usa stow
```

## Estructura de carpetas ignoradas

Estas carpetas NO están en git (ver .gitignore):
- `wallpapers/` - Fondos de pantalla locales (785MB)
- `.aider*` - Cache de aider
- `*.swp`, `*.swo` - Archivos temporales de vim

## Notas para Claude

- **NO versionar archivos grandes** (imágenes, binarios, etc.) en git
- Usar `.gitignore` para excluir wallpapers, caches, temporales
- **Home-manager está integrado en NixOS flake** - NO usar `home-manager switch`
- Para aplicar cambios: `sudo nixos-rebuild switch --flake ~/dotfiles#aurin --impure`
- Configs migradas a home-manager: alacritty, fish, picom, xmobar
- Configs aún con stow: xmonad
- El sistema es NixOS 25.05 en Aurin (Dual Xeon + RTX 5080)

## Comandos útiles del sistema

Ver `README.org` para lista completa, pero los principales:

```bash
aurin-info          # Info del sistema
fiio-k7-test        # Test audio FiiO K7
sunshine-test       # Test streaming
xeon-stress         # Stress test CPU
numa-info           # Info NUMA dual socket
```

## Referencias

- README.org (raíz) - Documentación completa de dotfiles
- nixos-aurin/README.org - Documentación NixOS Aurin específica
- .gitignore - Lista de archivos/carpetas ignorados

---

**Última actualización**: 2026-01-06
**Sistema**: Aurin (NixOS 25.05, Dual Xeon E5-2699v3, RTX 5080)
