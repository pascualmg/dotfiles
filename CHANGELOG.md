# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased] - 2026-01-23

### Added

- **XMonad Migration to Home-Manager (Phase 1-2)**: Completed migration from Stow
  - Phase 1: Cleanup xmonad.hs (removed dead code, fixed paths)
  - Phase 2: Created `modules/home-manager/programs/xmonad.nix` module
  - Phase 2.1: Fixed script paths (absolute paths for reliability)
  - Uses `.source` for hot-reload (10s recompile vs 3-5min nixos-rebuild)
  - Only `xmonad` and `composer` remain in Stow transition
  - Comprehensive migration guide in `XMONAD-MIGRATION-SUMMARY.md`

### Rejected

- **XMonad Phase 3 (Templates)**: Attempted and reverted (commit cff214e)
  - Attempted: Full template with `.text` (365 lines embedded in Nix)
  - Problem: Indentation bugs, xmobar broken, sobreingeniería
  - Lesson learned: `.source` files > templates for config hot-reload
  - Decision: Phase 2 is the correct solution (pragmatism > purity)
  - See `XMONAD-MIGRATION-SUMMARY.md` Phase 3 section for full analysis

## [1.1.0] - 2026-01-22

### Added

- **Forkeable Repo Guide**: "Use This Repo (WIP)" section in README.org
  - Quick Start guide for others wanting to use this config as base
  - Clear checklist of hardcoded values requiring customization
  - Table showing what's included vs. what's personal
  - Roadmap for full template support (after stow migration complete)
  - Transparent about current limitations (manual adaptation needed)

- **AI Agents Nixified (claude-code)**: Complete migration from Stow to home-manager
  - New module `modules/home-manager/programs/ai-agents.nix` for declarative management
  - Symlinks with `mkOutOfStoreSymlink` for editable config in `~/dotfiles/claude-code/`
  - Clear separation between config (managed) and state (runtime)
  - Clone-first: Same config on aurin, macbook, vespino
  - Comprehensive documentation in README.org (architecture, flow, troubleshooting)
  - Prepared for multi-client (opencode, gemini-cli) with commented blocks

### Changed

- **Removed claude-code from Stow**: Only xmonad and composer remain in transition
  - `passh.nix` line ~252: removed `claude-code` from stow command
  - Transition helper added in `ai-agents.nix` to clean old stow symlinks

### Fixed

- **Portable config**: `ai-agents.nix` imported in `core.nix` (not `passh.nix`)
  - Works on desktop, Android (nix-on-droid), and any system with home-manager

### Technical Details

- **Commit**: `4c32211` - feat: nixify claude-code config (remove stow dependency)
- **Implementation time**: ~10 minutes (via opencode CLI)
- **Testing**: `nix flake check` + `nixos-rebuild test` + symlink verification
- **Files modified**: 3 (ai-agents.nix created, core.nix + passh.nix updated)

## [1.0.0] - 2026-01-19

### Added

- **Clone-First Architecture**: All machines are identical clones, only differing in hardware
  - `modules/base/` - Unified base configuration for ALL machines
  - `modules/core/` - Core system modules (boot, locale, packages, security, etc.)
  - `hardware/` - Hardware-specific modules (NVIDIA, Apple, audio)
  - `hosts/` - Host-specific overrides only

- **Multi-machine support**:
  - **Aurin**: Dual Xeon E5-2699v3 (72 threads), 128GB RAM, RTX 5080
  - **MacBook**: MacBook Pro 13,2 (2016), Intel Skylake, HiDPI
  - **Vespino**: AMD CPU, RTX 2060

- **Desktop Environment**:
  - LightDM display manager (replaced GDM due to NVIDIA/XMonad issues)
  - GNOME desktop available on all machines
  - XMonad window manager with contrib and extras
  - Hyprland and Niri Wayland compositors available

- **Hardware modules**:
  - `hardware/nvidia/rtx5080.nix` - RTX 5080 with open drivers
  - `hardware/nvidia/rtx2060.nix` - RTX 2060 configuration
  - `hardware/apple/macbook-pro-13-2.nix` - MacBook Pro support (keyd, HiDPI, battery)
  - `hardware/apple/snd-hda-macbookpro.nix` - CS8409 audio codec support
  - `hardware/audio/fiio-k7.nix` - FiiO K7 DAC/AMP support

- **Home Manager integration**: Unified user configuration via NixOS flake
  - Alacritty, Fish, Picom, Xmobar managed via home-manager
  - XMonad config via stow (pending migration)

- **Virtualization**: Docker + libvirt/QEMU on all machines

- **Streaming**: Sunshine server support (NVENC on NVIDIA, software fallback)

- **Input configuration**:
  - Dual keyboard layout: US (default) + ES (Alt+Shift toggle)
  - Caps Lock remapped to Escape
  - libinput flat profile (raw mouse input)

### Fixed

- **GDM to LightDM migration**: GDM 49+ has broken dependencies with NVIDIA and XMonad
  - Symptom: System boots but never shows login screen
  - Solution: LightDM works with any session without complex dependencies

- **MacBook audio auto-configuration**: CS8409 codec wasn't auto-selecting profile
  - Added WirePlumber rule for automatic profile selection

### Changed

- Renamed `modules/common/` to `modules/core/` for clarity
- Removed legacy `nixos-aurin/`, `nixos-macbook/`, `nixos-vespino/` directories (6429 lines deleted)

### Architecture

```
dotfiles/
├── flake.nix                 # Entry point with mkSystem helper
├── modules/
│   ├── base/                 # Base config for ALL machines
│   │   ├── default.nix       # Imports core/* + desktop + virtualization
│   │   ├── desktop.nix       # LightDM + GNOME + XMonad
│   │   ├── sunshine.nix      # Streaming server
│   │   └── virtualization.nix
│   ├── core/                 # Core system modules
│   ├── desktop/              # Wayland: hyprland.nix, niri.nix
│   └── home-manager/         # User configuration
├── hardware/                 # Hardware-specific modules
│   ├── nvidia/
│   ├── apple/
│   └── audio/
└── hosts/                    # Host-specific overrides only
    ├── aurin/
    ├── macbook/
    └── vespino/
```

### Usage

```bash
# Check current machine
hostname

# Apply configuration
sudo nixos-rebuild switch --flake ~/dotfiles#<hostname> --impure

# Test without applying
sudo nixos-rebuild test --flake ~/dotfiles#<hostname> --impure

# Rollback
sudo nixos-rebuild switch --rollback
```

## [0.x] - Pre-1.0.0

Historical development before clone-first architecture:
- Individual configurations per machine
- Manual synchronization between hosts
- Legacy module structure

---

**Maintainer**: [@pascualmg](https://github.com/pascualmg)

**License**: MIT
