# ================================================================
# MINECRAFT SERVER - CONFIGURACIÓN MODULAR NIXOS PARA PRINCIPIANTES
# ================================================================
# Archivo: minecraft.nix
# Uso: import ./minecraft.nix en configuration.nix
# Versión: 1.2 - Limpio y sin redundancias
# Compatible: NixOS 24.05+

{ config, pkgs, lib, pkgsMaster, ... }:

{
  # ================================================================
  # CONFIGURACIÓN PRINCIPAL MINECRAFT SERVER
  # ================================================================

  services.minecraft-server = {
    # ---- CONFIGURACIÓN BÁSICA OBLIGATORIA ----
    enable = true; # true=servidor ON, false=servidor OFF
    eula = true; # OBLIGATORIO: Acepta términos de Mojang (debe ser true)
    declarative = true; # true=NixOS gestiona config, false=manual
    openFirewall = true; # true=abre puertos automáticamente, false=manual

    # ---- VERSIÓN DE MINECRAFT - DESDE MASTER ----
    # Usa pkgsMaster del flake para tener la versión más reciente
    package = pkgsMaster.minecraft-server;

    # Alternativas:
    # package = pkgs.minecraft-server;         # Versión estable (puede ser antigua)

    # ---- OPTIMIZACIÓN MEMORIA Y RENDIMIENTO ----
    # JVM = Java Virtual Machine (motor que ejecuta Minecraft)
    jvmOpts = lib.concatStringsSep " " [
      "-Xms16G" # RAM inicial al arrancar (6 GB - ajustar según tu PC)
      "-Xmx24G" # RAM máxima permitida (10 GB - ajustar según tu PC)
      "-XX:+UseG1GC" # Tipo limpieza memoria (G1 = mejor para juegos)
      "-XX:+UnlockExperimentalVMOptions" # Permite opciones avanzadas Java
      "-XX:G1HeapRegionSize=32M" # Tamaño regiones memoria (16MB para 10GB RAM)
      "-XX:G1NewSizePercent=30" # 30% memoria para objetos nuevos
      "-XX:G1MaxNewSizePercent=40" # Máximo 40% para objetos nuevos
      "-XX:+AlwaysPreTouch" # Reserva memoria al inicio (más estable)
      "-XX:+DisableExplicitGC" # Deshabilita limpieza manual memoria
      "-XX:+ParallelRefProcEnabled" # Procesamiento paralelo referencias
      "-XX:MaxGCPauseMillis=50" # Máximo 50ms pausa limpieza (menos lag)
    ];

    # ---- LISTA DE JUGADORES PERMITIDOS ----
    # IMPORTANTE: Obtener UUIDs en https://mcuuid.net/
    # UUID = código único de cada jugador de Minecraft
    whitelist = {
      "pascualmg" = "051370c0-a386-4fea-b6bd-04e4ff807b57";
      "levitaparamita" =
        "3274e1de-6bd9-4bf4-bad2-d31d22a48e41"; # Ya configurado
      # "nombre_amigo" = "uuid-de-tu-amigo-aqui";                  # Añadir más jugadores aquí
      # "otro_amigo" = "otro-uuid-aqui";                           # Formato: "nombre" = "uuid";
    };

    # ---- NOTA SOBRE ADMINISTRADORES ----
    # NixOS minecraft-server NO tiene opción "operators" declarativa
    # Los admins se configuran EN EL JUEGO o mediante archivos manuales:
    # 1. EN EL JUEGO: /op pascualmg (cuando seas el primer jugador)
    # 2. MANUAL: Editar /var/lib/minecraft/ops.json después del primer arranque
    # 3. VIA CONSOLA: echo "op pascualmg" >> /var/lib/minecraft/server_commands.txt

    # ---- CONFIGURACIÓN DETALLADA DEL MUNDO Y SERVIDOR ----
    serverProperties = {

      # === CONFIGURACIÓN DE RED ===
      server-port = 25565; # Puerto red (25565 = estándar Minecraft)
      server-ip = ""; # IP específica ("" = acepta desde cualquier IP)

      # === CONFIGURACIÓN BÁSICA DEL SERVIDOR ===
      motd =
        "§6⛏️ §bVespino trucao§6⛏️"; # Mensaje bienvenida (§=colores)
      max-players = 10; # Máximo jugadores simultáneos (1-999)

      # === CONFIGURACIÓN DEL MUNDO ===
      level-name = "world"; # Nombre carpeta mundo (donde se guarda)

      # TIPO DE MUNDO - RECOMENDADO PARA PRINCIPIANTES
      level-type = "minecraft:normal"; # Opciones disponibles:
      # "minecraft:normal" = mundo normal (RECOMENDADO para empezar)
      # "minecraft:large_biomes" = biomas 16x más grandes (para expertos)
      # "minecraft:flat" = mundo plano (para construcción)
      # "minecraft:amplified" = montañas súper altas (lag en PCs débiles)
      # "minecraft:single_biome_surface" = un solo bioma en todo el mundo

      level-seed = ""; # Semilla mundo ("" = aleatoria, "12345" = específica)
      # Semilla = código que determina cómo se genera el mundo
      # Misma semilla = mismo mundo siempre

      generate-structures =
        true; # true = pueblos/templos/dungeons, false = solo terreno
      allow-nether =
        true; # true = dimensión Nether disponible, false = solo overworld

      # === MODO DE JUEGO Y DIFICULTAD ===

      # MODO DE JUEGO INICIAL (nuevos jugadores)
      gamemode = 0; # 0 = Survival (normal - tienes que comer, puedes morir)
      # 1 = Creative (creativo - vuelas, bloques infinitos)
      # 2 = Adventure (aventura - para mapas custom)
      # 3 = Spectator (espectador - atraviesas bloques, invisible)

      # DIFICULTAD DEL MUNDO
      difficulty = 3; # 0 = Peaceful (sin monstruos, vida se regenera)
      # 1 = Easy (pocos monstruos, poco daño)
      # 2 = Normal (equilibrado - RECOMENDADO)
      # 3 = Hard (muchos monstruos, mucho daño)

      hardcore = false; # true = muerte permanente (se borra mundo al morir)
      # false = revivis al morir (RECOMENDADO para principiantes)

      # === CONFIGURACIÓN DE VISTA Y RENDIMIENTO ===

      view-distance = 32; # Distancia renderizado en chunks (6-32)
      # 1 chunk = 16x16 bloques
      # Más alto = ves más lejos pero más lag
      # 10 = básico, 16 = bueno, 20+ = épico pero pesado

      simulation-distance = 12; # Distancia simulación mobs/redstone (3-32)
      # Más bajo = mejor rendimiento
      # Más alto = mobs se mueven más lejos

      max-tick-time =
        120000; # Tiempo máximo por tick en ms (60000 = 60 segundos)
      # Si supera este tiempo, servidor se considera colgado

      # === SPAWNING Y MOBS (APARICIÓN DE CRIATURAS) ===

      spawn-monsters = true; # MONSTRUOS = Zombies, esqueletos, creepers, arañas
      # QUÉ HACEN: Aparecen de noche y te atacan
      # true = Aparecen monstruos (supervivencia normal)
      # false = Sin monstruos (mundo pacífico de noche)
      # RECOMENDADO: true (es parte de la diversión)

      spawn-animals = true; # ANIMALES = Vacas, cerdos, ovejas, pollos
      # QUÉ HACEN: Los matas para conseguir comida y materiales
      # true = Aparecen animales (puedes conseguir carne/lana)
      # false = Sin animales (solo comida de cultivos)
      # RECOMENDADO: true (necesitas comida y materiales)

      spawn-npcs = true; # NPCs = Aldeanos (personajes que comercian)
      # QUÉ HACEN: Viven en pueblos, intercambian items por esmeraldas
      # true = Hay aldeanos en pueblos (puedes comerciar)
      # false = Pueblos vacíos (sin comercio)
      # RECOMENDADO: true (comercio muy útil)

      max-entity-cramming = 24; # LÍMITE DE ENTIDADES JUNTAS
      # QUÉ ES: Máximo animales/monstruos en un bloque
      # PROBLEMA: Si hay muchas entidades juntas = LAG
      # SOLUCIÓN: Si hay más de 24, se lastiman hasta quedar 24
      # NÚMERO: 24 = bueno, más alto = más lag

      # === REGLAS DE JUGABILIDAD ===

      pvp = true; # PVP = Player vs Player (combate entre jugadores)
      # QUÉ ES: Posibilidad de atacar y matar a otros jugadores
      # true = Los jugadores pueden matarse entre sí
      # false = Los jugadores NO pueden hacerse daño
      # PARA AMIGOS: false (modo cooperativo, trabajáis juntos)
      # PARA COMPETIR: true (si queréis luchar)

      allow-flight = false; # PERMITIR VOLAR EN SURVIVAL
      # QUÉ ES: Normalmente solo vuelas en modo Creative
      # true = Permite volar en Survival (como hacer trampa)
      # false = Anti-cheat activado (no puedes volar en Survival)
      # RECOMENDADO: false (evita trampas)

      force-gamemode = false; # FORZAR MODO DE JUEGO AL CONECTAR
      # QUÉ HACE: Cambia automáticamente el modo al entrar
      # true = Todos entran en el modo configurado (gamemode=0)
      # false = Mantiene el último modo que usaron
      # RECOMENDADO: false (más flexible)

      player-idle-timeout = 0; # TIEMPO DE INACTIVIDAD ANTES DE ECHAR
      # QUÉ ES: Minutos sin hacer nada antes de kick automático
      # 0 = Nunca echa por inactividad
      # 30 = Echa tras 30 minutos sin moverse
      # PARA AMIGOS: 0 (pueden estar AFK sin problemas)

      # === PROTECCIÓN Y SEGURIDAD ===

      white-list = true; # WHITELIST = Lista de jugadores permitidos
      # true = Solo pueden entrar los de la lista (TÚ CONTROLAS)
      # false = Cualquier persona del mundo puede entrar
      # RECOMENDADO: true (evita trolls y griefers)

      online-mode = true; # VERIFICACIÓN DE CUENTAS
      # true = Solo cuentas oficiales de Minecraft (compradas)
      # false = Permite cuentas pirata/crackeadas
      # IMPORTANTE: Siempre true (más seguro)

      enable-command-block =
        false; # BLOQUES DE COMANDO = Bloques especiales que ejecutan comandos automáticamente
      # QUÉ SON: Bloques rojos que puedes programar para hacer cosas automáticas
      # EJEMPLOS: Teletransportar jugadores, dar items, cambiar tiempo
      # true = Los bloques comando funcionan (pueden ser peligrosos)
      # false = Los bloques comando no hacen nada (MÁS SEGURO)
      # PARA PRINCIPIANTES: false (no los necesitas aún)

      op-permission-level = 4; # NIVEL DE PERMISOS DE ADMINISTRADORES
      # QUÉ SON LOS PERMISOS: Qué comandos pueden usar los admins
      # 1 = Solo comandos básicos (/time, /weather)
      # 2 = Comandos moderación (/kick, /ban)
      # 3 = Comandos gestión (/gamemode, /tp)
      # 4 = TODOS los comandos (incluido /stop servidor)
      # RECOMENDADO: 4 (control total para ti como dueño)

      enforce-whitelist = true; # FORZAR WHITELIST A JUGADORES YA CONECTADOS
      # QUÉ SIGNIFICA: Si quitas a alguien de whitelist mientras juega
      # true = Lo echa automáticamente del servidor
      # false = Puede seguir jugando hasta que se desconecte
      # RECOMENDADO: true (control inmediato)

      enforce-secure-profile =
        true; # PERFILES SEGUROS (NUEVO EN MINECRAFT 1.19+)
      # QUÉ SON: Sistema verificación adicional de Microsoft
      # true = Solo permite jugadores con verificación extra
      # false = Permite jugadores sin verificación extra
      # RECOMENDADO: true (más seguridad)

      # === ADMINISTRACIÓN REMOTA (RCON) - DESHABILITADO ===

      enable-rcon = false; # RCON = Remote Control (control remoto del servidor)
      # QUÉ ES: Permite controlar el servidor desde fuera del juego
      # EJEMPLO: Ejecutar comandos desde terminal o apps
      # false = Deshabilitado (usas SSH en su lugar)
      # VENTAJA SIN RCON: Un puerto menos abierto = más seguro
      # NOTA: Puedes administrar con SSH + mc-admin commands

      # Puerto y password comentados porque RCON está deshabilitado
      # "rcon.port" = 25575;               # Puerto para RCON (no necesario)
      # "rcon.password" = "no_necesaria";  # Password RCON (no necesaria)

      # === INFORMACIÓN DEL SERVIDOR (QUERY) ===

      enable-query = true; # QUERY = Permite consultar información del servidor
      # QUÉ ES: Sistema para ver info servidor desde fuera
      # EJEMPLO: Cuántos jugadores hay, nombre servidor, etc.
      # true = Aparece en listas de servidores y scanners
      # false = Servidor "invisible" a herramientas externas
      # RECOMENDADO: true (útil para monitoreo)

      # NOTA: query.port se omite porque por defecto usa el mismo que server-port (25565)
      # Solo necesario si quieres puerto diferente: "query.port" = 25566;

      enable-status = true; # STATUS = Información básica del servidor
      # QUÉ ES: Permite ver estado cuando buscas servidores
      # EFECTO: Aparece info en lista "Add Server" del cliente
      # true = Muestra info (jugadores, ping, descripción)
      # false = No muestra información
      # RECOMENDADO: true (tu amigo puede ver si está online)

      hide-online-players = false; # OCULTAR LISTA DE JUGADORES ONLINE
      # QUÉ HACE: En la info del servidor, mostrar quién juega
      # false = Muestra "pascualmg, amigo1" en la lista
      # true = Muestra solo "2/10 jugadores" sin nombres
      # PARA AMIGOS: false (pueden ver quién está online)

      # === COMUNICACIÓN ===

      broadcast-console-to-ops = true; # MENSAJES DE CONSOLA A ADMINS
      # QUÉ ES: Cuando ejecutas comandos desde consola/SSH
      # true = Los admins en el juego ven los comandos ejecutados
      # false = Comandos de consola silenciosos
      # PARA TRANSPARENCIA: true (sabes qué hace el admin)

      # NOTA: broadcast-rcon-to-ops se omite porque RCON está deshabilitado

      # === PACKS DE RECURSOS - CONFIGURACIÓN OPCIONAL ===

      # NOTA: Configuración de resource packs omitida porque no es necesaria
      # Solo añadir si quieres forzar texturas específicas del servidor:
      # resource-pack = "https://ejemplo.com/texturas.zip";
      # resource-pack-sha1 = "hash_del_archivo";
      # require-resource-pack = true;        # Obligatorio usar
      # resource-pack-prompt = "Descargar texturas del servidor";

      # Para juego normal: cada jugador usa sus propias texturas

      # === CONFIGURACIÓN TÉCNICA (VALORES POR DEFECTO ADECUADOS) ===

      # NOTA: Estas configuraciones se omiten porque los valores por defecto son buenos:
      # max-world-size = 29999984;           # Límite mundo (defecto: 29999984 = 30M bloques)
      # network-compression-threshold = 256; # Compresión red (defecto: 256 bytes)
      # max-chained-neighbor-updates = 1000000; # Límite redstone (defecto: 1M)
      # rate-limit = 0;                      # Sin límite paquetes (defecto: 0)
      # use-native-transport = true;         # Transporte nativo (defecto: true)
      # enable-jmx-monitoring = false;       # Sin monitoreo JMX (defecto: false)
      # snooper-enabled = false;             # Sin telemetría (defecto: false)
      # log-ips = true;                      # Loggear IPs (defecto: true)
      # sync-chunk-writes = true;            # Escritura segura (defecto: true)

      # Solo configuramos lo que realmente queremos cambiar del defecto
    };

    # ---- DIRECTORIO DE DATOS ----
    dataDir = "/var/lib/minecraft"; # Carpeta donde se guardan mundos y config
  };

  # ================================================================
  # CONFIGURACIÓN FIREWALL - NO NECESARIA
  # ================================================================

  # NOTA: No necesitamos configuración manual de firewall porque
  # "openFirewall = true" en services.minecraft-server ya abre
  # automáticamente el puerto 25565 (TCP y UDP)

  # Solo sería necesario si quisiéramos puertos adicionales:
  # networking.firewall.allowedTCPPorts = [ 1234 ]; # Puerto extra

  # O si tuviéramos openFirewall = false y quisiéramos control manual

  # ================================================================
  # OPTIMIZACIONES ESPECÍFICAS MINECRAFT
  # ================================================================

  systemd.services.minecraft-server = {
    serviceConfig = {
      # Límites y protecciones específicos para Minecraft
      LimitNOFILE = 65536; # Máximo archivos abiertos simultáneos
      OOMScoreAdjust = -500; # Protección contra cierre por falta memoria
      Nice = -2; # Prioridad proceso (más alta que normal)

      # Configuración reinicio automático
      # NOTA: El módulo oficial ya configura Restart = "always"
      # Si quieres cambiarlo, usa lib.mkForce:
      # Restart = lib.mkForce "on-failure";  # Solo reiniciar si falla
      RestartSec = "10s"; # Espera 10s antes de reiniciar
    };
  };

  # ================================================================
  # HERRAMIENTAS DE ADMINISTRACIÓN
  # ================================================================

  # Script helper para administrar servidor fácilmente
  environment.systemPackages = with pkgs;
    [
      (writeShellScriptBin "mc-admin" ''
        #!/bin/bash
        echo "=== ADMINISTRADOR MINECRAFT ==="
        case "$1" in
          status)
            echo "📊 Estado del servidor:"
            systemctl status minecraft-server
            ;;
          logs)
            echo "📋 Logs en tiempo real (Ctrl+C para salir):"
            journalctl -u minecraft-server -f
            ;;
          restart)
            echo "🔄 Reiniciando servidor..."
            systemctl restart minecraft-server
            echo "✅ Servidor reiniciado"
            ;;
          stop)
            echo "🛑 Parando servidor..."
            systemctl stop minecraft-server
            echo "✅ Servidor parado"
            ;;
          start)
            echo "▶️ Iniciando servidor..."
            systemctl start minecraft-server
            echo "✅ Servidor iniciado"
            ;;
          backup)
            echo "💾 Creando backup..."
            timestamp=$(date +%Y%m%d-%H%M%S)
            mkdir -p /backup
            cp -r /var/lib/minecraft/world /backup/minecraft-$timestamp
            echo "✅ Backup creado en /backup/minecraft-$timestamp"
            ;;
          players)
            echo "👥 Para ver jugadores conectados:"
            echo "   1. Entrar al juego y usar: /list"
            echo "   2. O ver logs: mc-admin logs"
            ;;
          op)
            if [ -z "$2" ]; then
              echo "❌ Uso: mc-admin op <nombre_jugador>"
              echo "   Ejemplo: mc-admin op amigo1"
            else
              echo "👑 Haciendo admin a: $2"
              echo "op $2" | sudo tee -a /var/lib/minecraft/server_commands.txt
              echo "✅ $2 será admin cuando se conecte"
            fi
            ;;
          deop)
            if [ -z "$2" ]; then
              echo "❌ Uso: mc-admin deop <nombre_jugador>"
            else
              echo "👤 Quitando admin a: $2"
              echo "deop $2" | sudo tee -a /var/lib/minecraft/server_commands.txt
              echo "✅ $2 ya no será admin"
            fi
            ;;
          command)
            if [ -z "$2" ]; then
              echo "❌ Uso: mc-admin command <comando>"
              echo "   Ejemplo: mc-admin command 'say Hola servidor'"
            else
              echo "⚡ Ejecutando comando: $2"
              echo "$2" | sudo tee -a /var/lib/minecraft/server_commands.txt
              echo "✅ Comando enviado al servidor"
            fi
            ;;
          help|*)
            echo "🆘 Comandos disponibles:"
            echo "  mc-admin status      - Ver estado servidor"
            echo "  mc-admin logs        - Ver logs tiempo real"
            echo "  mc-admin restart     - Reiniciar servidor"
            echo "  mc-admin stop        - Parar servidor"
            echo "  mc-admin start       - Iniciar servidor"
            echo "  mc-admin backup      - Crear backup mundo"
            echo "  mc-admin players     - Info jugadores online"
            echo "  mc-admin op <user>   - Hacer admin a jugador"
            echo "  mc-admin deop <user> - Quitar admin a jugador"
            echo "  mc-admin command <cmd> - Ejecutar comando en servidor"
            echo "  mc-admin help        - Esta ayuda"
            ;;
        esac
      '')
    ];

  # ================================================================
  # INFORMACIÓN POST-INSTALACIÓN
  # ================================================================

  # Mensaje informativo cuando se aplica la configuración
  system.activationScripts.minecraft-info = ''
    echo "================================================="
    echo "🎮 MINECRAFT SERVER CONFIGURADO CORRECTAMENTE"
    echo "================================================="
    echo "📍 Puerto servidor: 25565"
    echo "🗺️ Tipo mundo: Normal (equilibrado para principiantes)"
    echo "⚔️ Modo: Survival Cooperativo (sin PvP)"
    echo "🛡️ Dificultad: Normal"
    echo "👥 Admin: pascualmg"
    echo "🔒 RCON: Deshabilitado (administración vía SSH)"
    echo ""
    echo "📋 Comandos útiles:"
    echo "   mc-admin status   - Ver estado"
    echo "   mc-admin logs     - Ver logs"
    echo "   mc-admin restart  - Reiniciar"
    echo "   mc-admin backup   - Backup manual"
    echo ""
    echo "🌐 Para conectarse desde fuera:"
    echo "   Dirección: $(curl -s ifconfig.me 2>/dev/null || echo 'TU_IP_PUBLICA'):25565"
    echo "================================================="
  '';

  # ================================================================
  # NOTAS IMPORTANTES PARA PRINCIPIANTES
  # ================================================================

  # RECORDATORIOS:
  # 1. UUID ya configurado para pascualmg
  # 2. Configuración optimizada para mundo normal
  # 3. Ajustar RAM (-Xms6G -Xmx10G) según tu PC
  # 4. IMPORTANTE: Usa master para última versión Minecraft
  # 5. Aplicar con: sudo nixos-rebuild switch
  # 6. Ver logs con: mc-admin logs
  # 7. Tu IP pública: curl ifconfig.me
}
