# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
