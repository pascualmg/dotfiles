# =============================================================================
# MODULO COMPARTIDO: Timezone y Locale
# =============================================================================
# Configuracion de zona horaria e idioma compartida por TODAS las maquinas
#
# CONSOLIDADO DE: aurin, macbook, vespino
#
# Valores:
#   - Timezone: Europe/Madrid
#   - Default locale: en_US.UTF-8 (para logs/CLI en ingles)
#   - Extra locales: es_ES.UTF-8 (para formatos locales: fechas, moneda, etc.)
# =============================================================================

{ config, pkgs, lib, ... }:

{
  # ===== TIMEZONE =====
  time.timeZone = "Europe/Madrid";

  # ===== LOCALE =====
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "es_ES.UTF-8";
      LC_IDENTIFICATION = "es_ES.UTF-8";
      LC_MEASUREMENT = "es_ES.UTF-8";
      LC_MONETARY = "es_ES.UTF-8";
      LC_NAME = "es_ES.UTF-8";
      LC_NUMERIC = "es_ES.UTF-8";
      LC_PAPER = "es_ES.UTF-8";
      LC_TELEPHONE = "es_ES.UTF-8";
      LC_TIME = "es_ES.UTF-8";
    };
  };
}
