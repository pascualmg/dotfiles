# Pendientes de Investigar

Documentacion de problemas sin resolver y areas que requieren investigacion futura.

---

## xmobar: Fuentes no escalan en HiDPI (MacBook Retina)

**Fecha**: 2026-01-12
**Estado**: SIN RESOLVER
**Sistema afectado**: vespino (MacBook Pro Retina)

### Sintoma

El parametro `size=X` en la especificacion de fuente xft NO cambia el tamano visual de la fuente en xmobar.

### Configuracion del entorno

- Xft.dpi=227
- GDK_SCALE=2
- Resolucion: 2560x1600

### Probado sin exito

| Configuracion | Resultado |
|---------------|-----------|
| `xft:Monoid Nerd Font:size=54:bold` | No cambia |
| `xft:DejaVu Sans Mono:size=54:bold` | No cambia |
| `xft:monospace:size=54` | No cambia |
| `pixelsize=64` en vez de `size` | No cambia |
| `dpi=96` forzado en la especificacion | No cambia |
| Eliminar `additionalFonts` | No cambia |

### Comportamiento observado

- La FUENTE cambia correctamente (de Monoid a DejaVu, etc.)
- El TAMANO de fuente NO cambia independientemente del valor
- Un config minimalista de prueba con solo `Run Date` SI respetaba el tamano

### Hipotesis

Puede haber algo en el config completo de xmobar que interfiere:
- Templates con `<fn=1>` (fuentes adicionales)
- StdinReader recibiendo datos de xmonad
- Alguna interaccion especifica entre Xft.dpi y xmobar

### Pendiente investigar

- Por que xmobar ignora el tamano de fuente en configs complejos pero no en simples
- Si es problema de como xmonad envia texto via StdinReader
- Si hay alguna interaccion especifica con Xft.dpi y xmobar
- Probar polybar o lemonbar como alternativas que manejen mejor HiDPI

---

## Soluciones implementadas en esta sesion

### Flake multi-maquina mejorado

- `modules/common/packages.nix` y `services.nix` se importan automaticamente en `mkNixosConfig`
- Paquetes compartidos: ripgrep, fd, bat, eza, jq, btop, zellij, tmux, byobu, powertop, iotop, iftop, inxi, neofetch
- TODAS las Nerd Fonts instaladas en common (~780MB)
- Services usan `lib.mkDefault` para evitar conflictos (SSH, PipeWire, Bluetooth)

### xmonad

- `setxkbmap us` usa `spawn` (no `spawnOnce`) para aplicar en cada Mod+q
- xmobar arriba + taffybar abajo funcionando juntos
- taffybar tiene opcion `barPosition = "Bottom"`

### Modulo xmobar

- `fontSize` ahora controla tanto el tamano de fuente como la altura de la barra
- Formula: `TopH = fontSize * 1.4`
- Usa `xft:Monoid Nerd Font:size=${fontSize}:bold`
