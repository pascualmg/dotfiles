# nix-index, comma y las formas de ejecutar programas en NixOS

## Introduccion: El Problema del "Comando No Encontrado"

Imagina este escenario clasico:

```bash
$ cowsay "hola"
bash: cowsay: command not found
```

En sistemas tradicionales (Ubuntu, Debian), tendrias que:
1. Buscar en Google que paquete contiene `cowsay`
2. Instalar el paquete con `apt install cowsay`
3. Ahora si, ejecutar `cowsay`

Esto es tedioso. Y en NixOS, donde no usamos `apt`, la solucion historica era
aun mas engorrosa. Pero hoy tenemos herramientas **mucho mejores**.

Este documento explica TODO sobre como ejecutar programas que no tienes
instalados en NixOS, desde la prehistoria hasta las herramientas modernas.

---

## Historia: Del Caos al Orden

### Era 1: El `command-not-found` Original (Ubuntu/Debian)

Ubuntu popularizo un sistema ingenioso: cuando escribias un comando que no
existia, en vez de solo decir "not found", te sugeria que paquete instalar:

```bash
$ cowsay "hola"
The program 'cowsay' is currently not installed. You can install it by typing:
sudo apt install cowsay
```

Esto usaba una base de datos local (`/var/lib/command-not-found/`) que mapeaba
binarios a paquetes. Era util, pero limitado a paquetes oficiales.

### Era 2: NixOS intenta copiarlo (`programs.command-not-found.enable`)

NixOS implemento algo similar con la opcion:

```nix
# La forma VIEJA (no uses esto)
programs.command-not-found.enable = true;
```

**El problema:** Esta opcion usaba una base de datos generada por Hydra (el CI
de NixOS) que:
- Solo cubria el canal estable/unstable oficial
- No incluia paquetes unfree
- Se actualizaba lentamente
- Frecuentemente estaba rota o desactualizada

Era mejor que nada, pero lejos de ser ideal.

### Era 3: nix-index (La Revolucion)

Alguien penso: "Y si en vez de depender de Hydra, generamos nuestra propia
base de datos indexando TODO nixpkgs?"

Asi nacio `nix-index`:

```bash
# Generar la base de datos (ADVERTENCIA: tarda 30-60 minutos)
$ nix-index
```

Este comando descarga y analiza TODOS los paquetes de nixpkgs, creando un
indice local en `~/.cache/nix-index/`. Luego puedes buscar:

```bash
$ nix-locate bin/cowsay
cowsay.out         /nix/store/...-cowsay-3.04/bin/cowsay
```

**Ventajas:**
- Indice completo de nixpkgs (incluyendo unfree)
- Funciona con cualquier revision de nixpkgs
- Busqueda super rapida

**Desventaja ENORME:**
- Generar el indice tarda 30-60 minutos
- Consume mucha RAM y CPU
- Hay que regenerarlo periodicamente

### Era 4: nix-index-database (Base de Datos Precompilada)

La comunidad penso: "Por que cada usuario tiene que generar el mismo indice?
Hagamoslo una vez y compartamoslo."

Nacio `nix-index-database`: una base de datos precompilada, actualizada
automaticamente, lista para usar:

```
                    ANTES                           AHORA
                    -----                           -----
Usuario A:  nix-index (60 min)           Descarga DB precompilada (30 seg)
Usuario B:  nix-index (60 min)           Descarga DB precompilada (30 seg)
Usuario C:  nix-index (60 min)           Descarga DB precompilada (30 seg)
                                   ↑
                             Hydra compila
                             el indice una vez
                             para todos
```

**Como se integra en tu flake:**

```nix
# flake.nix
inputs = {
  nix-index-database = {
    url = "github:nix-community/nix-index-database";
    inputs.nixpkgs.follows = "nixpkgs";
  };
};

# En tu configuracion
imports = [
  nix-index-database.hmModules.nix-index
];

programs.nix-index = {
  enable = true;
  # Esto es lo importante: usa la DB precompilada
};
```

### Era 5: comma (El Atajo Definitivo)

Y finalmente, alguien penso: "Y si en vez de buscar y luego ejecutar, hacemos
TODO en un solo paso?"

```bash
# En vez de:
$ nix-locate bin/cowsay
$ nix-shell -p cowsay
$ cowsay "hola"

# Simplemente:
$ , cowsay "hola"
 ______
< hola >
 ------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
```

**Si, es literal una coma seguida del comando.** comma busca automaticamente
que paquete contiene el binario, lo descarga temporalmente, y lo ejecuta.

---

## Las Diferentes Formas de Ejecutar Programas

Aqui viene la parte importante: hay VARIAS formas de ejecutar un programa que
no tienes instalado. Cada una tiene su lugar.

### Metodo 1: `nix-shell -p` (Legacy, pero funciona)

```bash
$ nix-shell -p cowsay
[nix-shell:~]$ cowsay "estoy en un shell temporal"
[nix-shell:~]$ exit
$
```

**Como funciona:**
1. Evalua nixpkgs para encontrar `cowsay`
2. Construye (o descarga del cache) el paquete
3. Te deja en un shell con `cowsay` en el PATH
4. Al salir, todo desaparece (no queda instalado)

**Caracteristicas:**
- Sintaxis: `nix-shell -p paquete1 paquete2 ...`
- Evaluacion: Usa el nixpkgs del sistema (`<nixpkgs>`)
- Es interactivo: te deja en un shell nuevo
- Legacy: usa el sistema antiguo de Nix (pre-flakes)

**Cuando usarlo:**
- Necesitas un shell interactivo con varios paquetes
- Scripts viejos que usan esta sintaxis
- Compatibilidad con sistemas sin flakes

**Ejemplo practico - desarrollo rapido:**
```bash
$ nix-shell -p python3 python3Packages.requests python3Packages.flask
[nix-shell:~]$ python3 -c "import flask; print(flask.__version__)"
3.0.0
[nix-shell:~]$ exit
```

### Metodo 2: `nix shell nixpkgs#` (La Forma Moderna con Flakes)

```bash
$ nix shell nixpkgs#cowsay
[shell]$ cowsay "estoy en un shell moderno"
[shell]$ exit
$
```

**Como funciona:**
1. Resuelve `nixpkgs` como flake (por defecto, el registry apunta a unstable)
2. Evalua el atributo `cowsay` de ese flake
3. Construye/descarga el paquete
4. Te deja en un shell con `cowsay` disponible

**Caracteristicas:**
- Sintaxis: `nix shell nixpkgs#paquete1 nixpkgs#paquete2`
- Usa flakes: reproducible y explicito
- El `#` separa el flake del atributo
- Puedes especificar revisiones exactas

**Ejemplos de sintaxis:**

```bash
# Desde el registry (nixpkgs apunta a unstable por defecto)
nix shell nixpkgs#cowsay

# Especificando una revision exacta
nix shell github:NixOS/nixpkgs/nixos-24.05#cowsay

# Multiples paquetes
nix shell nixpkgs#cowsay nixpkgs#lolcat

# Desde tu flake local
nix shell ~/dotfiles#algun-paquete
```

**Cuando usarlo:**
- Quieres reproducibilidad (puedes fijar la revision de nixpkgs)
- Necesitas un shell interactivo
- Estas en un sistema con flakes habilitado
- Quieres combinar paquetes de diferentes fuentes

### Metodo 3: `nix run nixpkgs#` (Ejecutar Sin Shell)

```bash
$ nix run nixpkgs#cowsay -- "ejecuto directamente"
 ______________________
< ejecuto directamente >
 ----------------------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
$  # <-- Vuelves inmediatamente a tu shell
```

**Como funciona:**
1. Igual que `nix shell`, resuelve y construye el paquete
2. Pero en vez de abrir un shell, ejecuta el binario principal directamente
3. Cuando termina, vuelves a tu shell original

**Caracteristicas:**
- Sintaxis: `nix run nixpkgs#paquete -- argumentos`
- El `--` separa opciones de nix de argumentos del programa
- No abre un shell interactivo
- Ideal para ejecutar algo una vez

**Cuando usarlo:**
- Quieres ejecutar un comando una sola vez
- No necesitas shell interactivo
- Scripts que invocan herramientas externas

**Comparacion:**

```bash
# nix shell: Te quedas en un shell nuevo
$ nix shell nixpkgs#cowsay
[shell]$ cowsay "hola"
[shell]$ cowsay "adios"
[shell]$ exit

# nix run: Ejecuta y termina
$ nix run nixpkgs#cowsay -- "hola"
$ # Ya estas de vuelta
```

### Metodo 4: `, paquete` (comma - El Atajo Magico)

```bash
$ , cowsay "el metodo mas facil"
```

**Como funciona:**
1. comma invoca `nix-locate` para buscar que paquete tiene el binario
2. Una vez encontrado, usa `nix run` o `nix shell` para ejecutarlo
3. Todo automatico, cero configuracion

**Caracteristicas:**
- Sintaxis: `, binario argumentos`
- Busqueda automatica usando nix-index
- Cero friccion - escribes y funciona
- Requiere nix-index-database configurado

**Cuando usarlo:**
- SIEMPRE (es el default para uso casual)
- Probar programas rapidamente
- "Quiero ejecutar X y no se en que paquete esta"

**Ejemplos practicos:**

```bash
# Ejecutar cowsay sin saber que paquete es
$ , cowsay "funciona!"

# Si hay ambiguedad, comma pregunta
$ , python
Multiple packages provide 'python':
  1) python2
  2) python3
  3) python312
Select [1-3]:

# Pasar argumentos complejos
$ , ffmpeg -i video.mp4 -c:v libx264 output.mp4

# Comandos con pipes (el comma solo afecta al primer comando)
$ , cowsay "hola" | , lolcat
```

---

## Tabla Comparativa: Cual Usar

```
+-------------------+------------+------------+-----------+---------------+
|     Metodo        |  Flakes?   | Interactivo|  Busqueda | Caso de Uso   |
+-------------------+------------+------------+-----------+---------------+
| nix-shell -p      |    No      |     Si     |  Manual   | Legacy/compat |
| nix shell nixpkgs#|    Si      |     Si     |  Manual   | Shell temporal|
| nix run nixpkgs#  |    Si      |     No     |  Manual   | Ejecutar 1 vez|
| , (comma)         |    Si      |     No     |  Auto     | USO DIARIO    |
+-------------------+------------+------------+-----------+---------------+
```

### Diagrama de Decision

```
Quiero ejecutar un programa que no tengo instalado
                    |
                    v
        Se que paquete es? ----No----> Usa `, comando`
                    |                      (comma)
                   Si
                    |
                    v
        Necesito shell interactivo? ----No----> nix run nixpkgs#pkg
                    |
                   Si
                    |
                    v
        Necesito flakes/reproducibilidad?
                    |
            +-------+-------+
            |               |
           Si              No
            |               |
            v               v
    nix shell nixpkgs#   nix-shell -p
```

---

## Como Funciona nix-index Internamente

### La Base de Datos

nix-index crea un indice que mapea rutas de archivos a paquetes:

```
/nix/store/xxx-cowsay-3.04/bin/cowsay  -->  cowsay
/nix/store/yyy-python3-3.12/bin/python3 -->  python3
/nix/store/zzz-git-2.43/bin/git        -->  git
...
```

Esta base de datos vive en `~/.cache/nix-index/` y ocupa unos ~300MB.

### nix-locate: La Herramienta de Busqueda

```bash
# Buscar que paquete tiene un binario
$ nix-locate bin/cowsay
cowsay.out         /nix/store/...-cowsay-3.04/bin/cowsay

# Buscar por nombre parcial
$ nix-locate --regex 'bin/python.*'
python2.out        /nix/store/...-python2-2.7.18/bin/python2
python3.out        /nix/store/...-python3-3.12/bin/python3
python312.out      /nix/store/...-python3-3.12/bin/python3.12
...

# Buscar librerias
$ nix-locate libssl.so
openssl.out        /nix/store/...-openssl-3.0/lib/libssl.so

# Buscar headers
$ nix-locate 'include/openssl/ssl.h'
openssl.dev        /nix/store/...-openssl-3.0-dev/include/openssl/ssl.h
```

### Por Que Usamos nix-index-database

```
                    GENERAR LOCALMENTE               USAR PRECOMPILADA
                    ------------------               ------------------
Tiempo inicial:     30-60 minutos                    30 segundos
CPU/RAM:            Intensivo                        Minimal
Actualizacion:      Manual (nix-index)               Automatica (flake update)
Consistencia:       Depende de tu nixpkgs            Siempre sync con nixpkgs
```

La base de datos precompilada se actualiza diariamente via GitHub Actions y
esta sincronizada con nixpkgs-unstable. Cuando haces `nix flake update`,
tambien se actualiza tu indice.

### Integracion con el Shell

nix-index puede integrarse con bash/zsh/fish para el famoso "command not found":

```nix
# En tu home-manager config
programs.nix-index = {
  enable = true;
  enableBashIntegration = true;  # o enableZshIntegration, enableFishIntegration
};
```

Con esto, cuando escribes un comando que no existe:

```bash
$ cowsay "hola"
The program 'cowsay' is provided by the following packages:
  - cowsay (cowsay)

You can run it with:
  nix shell nixpkgs#cowsay
  nix run nixpkgs#cowsay -- "hola"
```

Y si tienes comma instalado, simplemente ejecutas `, cowsay "hola"`.

---

## Ejemplos de Uso Cotidiano

### Probar un Programa Antes de Instalarlo

```bash
# "Quiero ver si neofetch me gusta antes de agregarlo a mi config"
$ , neofetch

# Si te gusta, agregalo a home.packages
# Si no, no haces nada - no quedo instalado
```

### Ejecutar Algo Una Sola Vez

```bash
# Convertir un video (no necesitas ffmpeg instalado permanentemente)
$ , ffmpeg -i input.mp4 -c:v libx265 output.mp4

# Generar un QR code
$ , qrencode -o qr.png "https://example.com"

# Comprimir con 7zip
$ , 7z a archivo.7z carpeta/
```

### Buscar Que Paquete Provee un Binario

```bash
# "Como se llama el paquete que tiene el comando 'rg'?"
$ nix-locate bin/rg
ripgrep.out        /nix/store/...-ripgrep-14.1/bin/rg

# "Que paquete tiene libcurl?"
$ nix-locate 'lib/libcurl.so'
curl.out           /nix/store/...-curl-8.5/lib/libcurl.so
curlFull.out       /nix/store/...-curl-8.5-full/lib/libcurl.so
```

### Desarrollo Rapido

```bash
# Necesito Python con algunas librerias para un script rapido
$ nix shell nixpkgs#python3 nixpkgs#python3Packages.requests
[shell]$ python3 mi-script.py
[shell]$ exit

# O para proyectos serios, usa flakes (ver templates/flake-templates/)
```

### Debugging y Herramientas del Sistema

```bash
# Ver el arbol de procesos
$ , pstree

# Analizar uso de disco
$ , ncdu /home

# Monitor de red
$ , nethogs

# Benchmark rapido
$ , hyperfine 'sleep 0.1' 'sleep 0.2'
```

---

## Configuracion en Tu Sistema

### Donde Esta Configurado

En tu flake, nix-index-database esta como input:

```nix
# flake.nix
inputs = {
  nix-index-database = {
    url = "github:nix-community/nix-index-database";
    inputs.nixpkgs.follows = "nixpkgs";
  };
};
```

Y se importa en home-manager:

```nix
# modules/home-manager/passh.nix (o donde tengas tu config)
imports = [
  inputs.nix-index-database.hmModules.nix-index
];

# comma viene incluido automaticamente con nix-index-database
```

### Verificar Que Funciona

```bash
# Verificar que nix-locate funciona
$ nix-locate bin/cowsay
cowsay.out ...

# Verificar que comma funciona
$ , cowsay "funciona!"

# Ver donde esta la base de datos
$ ls -la ~/.cache/nix-index/
```

### Actualizar la Base de Datos

```bash
# La DB se actualiza cuando actualizas el flake
$ nix flake update ~/dotfiles

# Luego rebuild
$ sudo nixos-rebuild switch --flake ~/dotfiles#aurin --impure
```

---

## Problemas Comunes y Soluciones

### "command not found" pero el paquete existe

```bash
$ cowsay "hola"
bash: cowsay: command not found
```

**Solucion:** Usa comma o nix-locate:
```bash
$ , cowsay "hola"
# o
$ nix-locate bin/cowsay
```

### nix-locate no encuentra nada

```bash
$ nix-locate bin/programa-raro
(no output)
```

**Causas posibles:**
1. El programa no existe en nixpkgs
2. La base de datos esta desactualizada

**Solucion:**
```bash
# Actualizar la DB
$ nix flake update nix-index-database ~/dotfiles
$ sudo nixos-rebuild switch --flake ~/dotfiles#aurin --impure

# O buscar manualmente en nixpkgs
$ nix search nixpkgs programa-raro
```

### comma pregunta multiples opciones

```bash
$ , python
Multiple packages provide 'python':
  1) python2
  2) python3
Select [1-3]:
```

**Solucion:** Especifica el paquete exacto:
```bash
$ , python3 script.py
```

### Error de permisos con comma

```bash
$ , cowsay
error: unable to download ... permission denied
```

**Causa:** Problemas con el daemon de nix o cache.

**Solucion:**
```bash
# Verificar que el daemon esta corriendo
$ systemctl status nix-daemon

# Limpiar cache si es necesario
$ nix-collect-garbage
```

---

## Tips Avanzados

### Alias Utiles

```bash
# En tu config de fish/bash/zsh
alias try=','                    # , cowsay -> try cowsay
alias nx='nix shell nixpkgs#'    # nx cowsay -> shell con cowsay
alias nr='nix run nixpkgs#'      # nr cowsay -- hola
```

### Usar Diferentes Versiones

```bash
# Version especifica de nixpkgs
$ nix run github:NixOS/nixpkgs/nixos-23.11#cowsay -- "version vieja"

# Desde tu flake con pkgsMaster
$ nix run ~/dotfiles#claude-code  # Si lo tienes expuesto
```

### Crear Scripts Reproducibles

```bash
#!/usr/bin/env nix-shell
#!nix-shell -i bash -p cowsay lolcat

# Este script se auto-provee sus dependencias
cowsay "Este script trae sus propias dependencias" | lolcat
```

O con flakes (mas moderno):

```bash
#!/usr/bin/env -S nix shell nixpkgs#cowsay nixpkgs#lolcat --command bash

cowsay "Version con flakes" | lolcat
```

---

## Resumen Visual

```
+------------------------------------------------------------------+
|                    EJECUTAR PROGRAMAS EN NIXOS                    |
+------------------------------------------------------------------+
|                                                                   |
|  FORMA RECOMENDADA (uso diario):                                  |
|  ================================                                 |
|                                                                   |
|    $ , comando argumentos                                         |
|                                                                   |
|  Busca automaticamente, descarga, ejecuta. Cero friccion.         |
|                                                                   |
+------------------------------------------------------------------+
|                                                                   |
|  ALTERNATIVAS (casos especificos):                                |
|  =================================                                |
|                                                                   |
|  nix shell nixpkgs#pkg     ->  Shell interactivo con flakes       |
|  nix run nixpkgs#pkg       ->  Ejecutar una vez con flakes        |
|  nix-shell -p pkg          ->  Shell interactivo legacy           |
|                                                                   |
+------------------------------------------------------------------+
|                                                                   |
|  BUSQUEDA:                                                        |
|  =========                                                        |
|                                                                   |
|  nix-locate bin/comando    ->  Que paquete tiene este binario?    |
|  nix search nixpkgs nombre ->  Buscar paquetes por nombre         |
|                                                                   |
+------------------------------------------------------------------+
|                                                                   |
|  STACK TECNOLOGICO:                                               |
|  ==================                                               |
|                                                                   |
|  nix-index-database  -->  Base de datos precompilada              |
|         |                                                         |
|         v                                                         |
|     nix-index  -->  Herramienta de indexado (nix-locate)          |
|         |                                                         |
|         v                                                         |
|      comma (,)  -->  El atajo que lo une todo                     |
|                                                                   |
+------------------------------------------------------------------+
```

---

## Siguientes Pasos

Ahora que entiendes como funciona:

1. **Practica con comma:** Ejecuta programas random con `, programa`
2. **Explora nix-locate:** Busca que paquetes proveen diferentes binarios
3. **Crea scripts:** Usa los shebangs de nix-shell para scripts reproducibles
4. **Investiga flakes:** Mira como `nix develop` crea entornos de desarrollo

---

**Documento creado:** 2026-01-16
**Autor:** NixOS Guru (asistido por Claude)
**Sistema:** Aurin (NixOS 25.05)
