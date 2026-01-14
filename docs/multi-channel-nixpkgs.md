# Sistema Multi-Channel en NixOS Flakes

## El Problema: Paquetes Desactualizados

Imagina esta situacion: necesitas `claude-code` version 2.1.6, pero `nixpkgs-unstable`
solo tiene la 2.1.2. Normalmente tendrias que esperar dias o semanas hasta que el
paquete se actualice en unstable.

**El problema en numeros:**

```
nixpkgs-master  -->  claude-code 2.1.6  (commits de hoy)
     |
     | ~2-7 dias de propagacion
     v
nixpkgs-unstable --> claude-code 2.1.2  (lo que tienes ahora)
```

Los paquetes fluyen asi:

1. Alguien hace PR a nixpkgs con la nueva version
2. Se mergea a `master`
3. Pasan tests de CI (Hydra)
4. Se propaga a `nixos-unstable` (2-7 dias)
5. Eventualmente llega a `nixos-stable` (meses)

**Solucion tradicional (mala):** Esperar. O peor: instalar manualmente fuera de Nix.

**Nuestra solucion:** Sistema multi-channel con `pkgsMaster`.

---

## La Arquitectura: Dos Fuentes de Paquetes

```
                          flake.nix
                              |
              +---------------+---------------+
              |                               |
              v                               v
     inputs.nixpkgs                  inputs.nixpkgs-master
     (nixos-unstable)                    (master)
              |                               |
              v                               v
         import ->                       import ->
              |                               |
              v                               v
            pkgs                          pkgsMaster
              |                               |
              +---------------+---------------+
                              |
                              v
                       specialArgs = {
                         inherit pkgsMaster;
                       };
                              |
                              v
                    Todos los modulos NixOS
                    y Home Manager pueden usar:
                    - pkgs.firefox (unstable)
                    - pkgsMaster.claude-code (master)
```

### Diagrama de Flujo Detallado

```
+------------------+          +---------------------+
|   flake.lock     |          |     flake.lock      |
| nixpkgs: abc123  |          | nixpkgs-master: xyz |
+--------+---------+          +---------+-----------+
         |                              |
         v                              v
+------------------+          +---------------------+
| inputs.nixpkgs   |          | inputs.nixpkgs-master|
| (unstable)       |          | (bleeding-edge)     |
+--------+---------+          +---------+-----------+
         |                              |
         | import nixpkgs {             | import nixpkgs-master {
         |   system = "x86_64-linux";   |   system = "x86_64-linux";
         |   config.allowUnfree = true; |   config.allowUnfree = true;
         | };                           | };
         v                              v
+------------------+          +---------------------+
|      pkgs        |          |     pkgsMaster      |
| (99% paquetes)   |          | (paquetes nuevos)   |
+--------+---------+          +---------+-----------+
         |                              |
         +------------+  +--------------+
                      |  |
                      v  v
            +-------------------+
            |   specialArgs     |
            | {                 |
            |   inherit inputs; |
            |   inherit pkgsMaster; |
            | }                 |
            +---------+---------+
                      |
                      v
            +-------------------+
            | configuration.nix |
            | passh.nix         |
            | cualquier modulo  |
            +-------------------+
```

---

## Como Usar pkgsMaster en Tus Modulos

### Paso 1: Declarar el Argumento

En cualquier modulo que quiera usar `pkgsMaster`, anadelo a los argumentos:

```nix
# modules/home-manager/passh.nix

{ config, pkgs, pkgsMaster, lib, ... }:
#              ^^^^^^^^^^
#              Nuevo argumento disponible gracias a specialArgs

{
  home.packages = with pkgs; [
    # Paquetes normales de unstable
    firefox
    git
    ripgrep

  ] ++ [
    # Paquetes de master (bleeding-edge)
    pkgsMaster.claude-code    # Version 2.1.6 cuando unstable tiene 2.1.2
    # pkgsMaster.otro-paquete
  ];
}
```

### Paso 2: Entender la Sintaxis

```nix
# OPCION A: with pkgs + lista separada para pkgsMaster
home.packages = with pkgs; [
  firefox
  git
] ++ [
  pkgsMaster.claude-code
];

# OPCION B: Sin with, todo explicito (mas claro, mas verboso)
home.packages = [
  pkgs.firefox
  pkgs.git
  pkgsMaster.claude-code
];

# OPCION C: Mezclar en la misma lista (funciona pero confuso)
home.packages = with pkgs; [
  firefox
  git
  pkgsMaster.claude-code  # Esto funciona! pkgsMaster esta en scope
];
```

**Recomendacion:** Usa Opcion A - separa claramente que viene de cada fuente.

### Paso 3: Modulos NixOS vs Home Manager

Ambos tienen acceso a `pkgsMaster` gracias a como esta configurado el flake:

```nix
# En el flake.nix, ambos reciben pkgsMaster:

# Para modulos NixOS (system-wide):
specialArgs = {
  inherit pkgsMaster;  # <- Accesible en configuration.nix y modulos
};

# Para Home Manager (user-level):
extraSpecialArgs = {
  inherit pkgsMaster;  # <- Accesible en passh.nix y submodulos
};
```

---

## Comandos Utiles para Gestionar Inputs

### Ver Estado Actual del Lock

```bash
# Ver que commits tienes bloqueados
cat ~/dotfiles/flake.lock | jq '.nodes.nixpkgs.locked.rev'
cat ~/dotfiles/flake.lock | jq '.nodes["nixpkgs-master"].locked.rev'

# Ver fechas de los commits
nix flake metadata ~/dotfiles
```

### Actualizar Inputs Selectivamente

```bash
# CUIDADO: Esto puede romper cosas!
# Siempre haz backup o asegurate de poder hacer rollback

# Actualizar SOLO nixpkgs-master (lo mas seguro)
nix flake lock --update-input nixpkgs-master ~/dotfiles

# Actualizar SOLO nixpkgs (unstable)
nix flake lock --update-input nixpkgs ~/dotfiles

# Actualizar TODO (nixpkgs + nixpkgs-master + home-manager + ...)
nix flake update ~/dotfiles
```

### Estrategia Recomendada

```bash
# 1. Primero, ver que cambiaria
nix flake lock --update-input nixpkgs-master ~/dotfiles
git diff flake.lock  # Ver el nuevo commit

# 2. Probar sin hacer switch permanente
sudo nixos-rebuild test --flake ~/dotfiles#aurin --impure

# 3. Si todo funciona, aplicar
sudo nixos-rebuild switch --flake ~/dotfiles#aurin --impure

# 4. Si algo falla, rollback inmediato
sudo nixos-rebuild switch --rollback
```

### Bloquear a un Commit Especifico

Si master tiene un bug, puedes bloquear a un commit anterior:

```bash
# Bloquear nixpkgs-master a un commit especifico
nix flake lock \
  --override-input nixpkgs-master github:NixOS/nixpkgs/abc123def \
  ~/dotfiles
```

---

## Cuando Usar Master vs Unstable

### Usar `pkgs` (unstable) para:

| Caso | Ejemplo | Razon |
|------|---------|-------|
| Paquetes estables | firefox, git | Ya probados, funcionan |
| Sistema base | gcc, glibc | Romper esto = romper todo |
| Dependencias complejas | python, haskell | Muchas interdependencias |
| Servicios del sistema | nginx, postgres | Estabilidad critica |

### Usar `pkgsMaster` para:

| Caso | Ejemplo | Razon |
|------|---------|-------|
| Paquetes bleeding-edge | claude-code | Necesitas la ultima version |
| Paquetes nuevos | algo recien agregado | Aun no llego a unstable |
| Fixes de seguridad urgentes | openssl | El fix esta en master |
| Experimentacion | cualquier cosa | Quieres probar lo nuevo |

### Trade-offs

```
                    UNSTABLE                    MASTER
                    --------                    ------
Estabilidad:        Alta                        Media-Baja
Tiempo de espera:   2-7 dias                    0 (inmediato)
Testing:            CI de Hydra                 Solo build basico
Riesgo de rotura:   Bajo                        Medio-Alto
Reproducibilidad:   Buena                       Buena (mismo lock)
```

### Regla de Oro

> **Usa `pkgsMaster` SOLO para paquetes aislados que no tienen muchas dependencias
> y donde necesitas la ultima version urgentemente.**

Ejemplos buenos para master:
- `claude-code` (CLI standalone)
- `rip` (herramienta simple)
- `dust` (visualizador de disco)

Ejemplos MALOS para master:
- `firefox` (cientos de dependencias)
- `python3` (miles de paquetes dependen de el)
- `glibc` (todo el sistema depende de el)

---

## Por Que NO Usamos Overlay

### Que es un Overlay?

Un overlay es una forma de "sobrescribir" paquetes en nixpkgs:

```nix
# Ejemplo de overlay (NO lo usamos)
nixpkgs.overlays = [
  (final: prev: {
    claude-code = (import nixpkgs-master { ... }).claude-code;
  })
];
```

### Por Que Evitamos Overlays Aqui

**1. Complejidad innecesaria**

```nix
# Con overlay: indirecto, dificil de seguir
nixpkgs.overlays = [
  (final: prev: {
    claude-code = pkgsMaster.claude-code;
  })
];
# Luego usas: pkgs.claude-code

# Sin overlay: directo, obvio
home.packages = [ pkgsMaster.claude-code ];
# Usas: pkgsMaster.claude-code (explicito de donde viene)
```

**2. Claridad en el codigo**

Cuando lees `pkgsMaster.claude-code`, sabes EXACTAMENTE de donde viene.
Cuando lees `pkgs.claude-code` con overlay, tienes que buscar el overlay.

**3. Evaluacion extra**

Los overlays se evaluan para TODOS los paquetes, incluso los que no usas.
Con `pkgsMaster` explicito, solo se evalua lo que usas.

**4. Debugging mas facil**

```bash
# Con overlay: donde esta el problema?
error: undefined variable 'claude-code'
# Tienes que revisar overlays, modulos, etc.

# Sin overlay: obvio
error: attribute 'claude-code' missing at pkgsMaster
# Sabes exactamente que nixpkgs-master no tiene ese paquete
```

### Cuando SI Usar Overlays

Los overlays son utiles para:

- Parchear paquetes (modificar src, patches, etc.)
- Crear variantes de paquetes (firefox-with-plugins)
- Overrides sistematicos (cambiar version de una dependencia globalmente)

Para simplemente "traer un paquete de otra fuente", `specialArgs` es mas simple.

---

## Configuracion Actual en Tu Flake

### flake.nix (extracto relevante)

```nix
{
  inputs = {
    # Canal principal: unstable
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Canal secundario: master (bleeding-edge)
    nixpkgs-master.url = "github:NixOS/nixpkgs/master";

    # Home Manager sigue a nixpkgs (unstable)
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, nixpkgs-master, ... }:
    let
      system = "x86_64-linux";

      # Importar ambos canales
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      pkgsMaster = import nixpkgs-master {
        inherit system;
        config.allowUnfree = true;
      };
    in {
      nixosConfigurations.aurin = nixpkgs.lib.nixosSystem {
        # Pasar pkgsMaster a todos los modulos
        specialArgs = { inherit pkgsMaster; };

        # Home Manager tambien lo recibe
        modules = [
          home-manager.nixosModules.home-manager
          {
            home-manager.extraSpecialArgs = { inherit pkgsMaster; };
          }
        ];
      };
    };
}
```

### passh.nix (uso de pkgsMaster)

```nix
{ config, pkgs, pkgsMaster, lib, ... }:

{
  home.packages = with pkgs; [
    # ~150 paquetes de unstable...
    firefox
    git
    # etc.
  ] ++ [
    # Paquetes de master (bleeding-edge)
    pkgsMaster.claude-code  # 2.1.6 cuando unstable tiene 2.1.2
  ];
}
```

---

## Problemas Comunes y Soluciones

### Error: "attribute X missing"

```
error: attribute 'nuevo-paquete' missing
```

**Causa:** El paquete no existe en ese canal (ni unstable ni master).

**Solucion:** Verificar que existe:
```bash
nix-env -qaP -f '<nixpkgs>' | grep nuevo-paquete
```

### Error: Hash Mismatch

```
error: hash mismatch in fixed-output derivation
```

**Causa:** El paquete en master tiene un hash desactualizado (comun en paquetes
que descargan cosas de internet).

**Solucion temporal:** Comentar el paquete y reportar el bug, o esperar a que
se arregle en master.

```nix
# duckstation  # TEMP: hash mismatch (2026-01-14)
```

### Error: Collisions

```
error: collision between /nix/store/xxx-pkg-1.0 and /nix/store/yyy-pkg-1.1
```

**Causa:** El mismo paquete instalado de dos fuentes con versiones diferentes.

**Solucion:** Usar solo una fuente para ese paquete.

---

## Resumen Visual

```
+------------------------------------------------------------------+
|                        TU SISTEMA NIXOS                          |
+------------------------------------------------------------------+
|                                                                  |
|  99% de paquetes          |  1% paquetes bleeding-edge           |
|  (pkgs = unstable)        |  (pkgsMaster = master)               |
|                           |                                      |
|  firefox                  |  claude-code                         |
|  git                      |  (otros que necesites)               |
|  python3                  |                                      |
|  gcc                      |                                      |
|  ... +150 mas             |                                      |
|                           |                                      |
+------------------------------------------------------------------+
|                                                                  |
|  flake.lock asegura reproducibilidad para AMBOS canales         |
|  Puedes actualizar cada uno independientemente                   |
|                                                                  |
+------------------------------------------------------------------+
```

---

## Siguiente Paso: Agregar Mas Paquetes de Master

Si en el futuro necesitas otro paquete de master:

```nix
# En passh.nix o cualquier modulo
home.packages = with pkgs; [
  # paquetes normales...
] ++ [
  pkgsMaster.claude-code
  pkgsMaster.nuevo-paquete  # <- Agregar aqui
];
```

Luego:
```bash
# Actualizar master para tener el paquete
nix flake lock --update-input nixpkgs-master ~/dotfiles

# Rebuild
sudo nixos-rebuild switch --flake ~/dotfiles#aurin --impure
```

---

**Documento creado:** 2026-01-14
**Autor:** NixOS Guru (asistido por Claude)
**Sistema:** Aurin (NixOS 25.05)
