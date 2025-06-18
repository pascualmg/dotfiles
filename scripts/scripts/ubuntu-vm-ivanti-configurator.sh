#!/bin/bash
# Script de auto-configuración para VM Ubuntu VPN
# Convierte Ubuntu vanilla en router VPN funcional en 2 minutos

set -e
echo "🚀 CONFIGURANDO VM UBUNTU COMO ROUTER VPN..."

# ===== VERIFICACIONES =====
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Ejecutar como root: sudo $0"
    exit 1
fi

BACKUP_DIR="/root/backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

# ===== 1. BACKUP Y INSTALACIÓN =====
echo "📦 Instalando paquetes necesarios..."
cp /etc/resolv.conf "$BACKUP_DIR/" 2>/dev/null || true
cp -r /etc/netplan "$BACKUP_DIR/" 2>/dev/null || true

apt-get update
apt-get install -y dnsmasq iptables-persistent net-tools curl

# ===== 2. CONFIGURAR RED ESTÁTICA =====
echo "🌐 Configurando red estática..."
cat > /etc/netplan/00-installer-config.yaml << 'EOF'
network:
  version: 2
  ethernets:
    enp1s0:
      addresses:
        - 192.168.53.12/24
      routes:
        - to: default
          via: 192.168.53.10
      nameservers:
        addresses: [127.0.0.1]
        search: [grupo.vocento]
EOF

chmod 600 /etc/netplan/00-installer-config.yaml

# ===== 3. CONFIGURAR DNS/DNSMASQ =====
echo "🔍 Configurando DNS..."
cat > /etc/dnsmasq.conf << 'EOF'
# Configuración para VPN Vocento
listen-address=127.0.0.1,192.168.53.12
bind-interfaces
no-resolv

# DNS servers VPN (se actualizan cuando VPN conecta)
server=192.168.201.38
server=192.168.201.43

# Configuración de dominio
domain=grupo.vocento
local=/vocento.com/

# Logging
log-queries
log-facility=/var/log/dnsmasq.log
EOF

# ===== 4. HABILITAR IP FORWARDING =====
echo "📡 Habilitando IP forwarding..."
echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/99-vpn-forward.conf
sysctl -p /etc/sysctl.d/99-vpn-forward.conf

# ===== 5. CONFIGURAR IPTABLES =====
echo "🔥 Configurando firewall..."
# Limpiar reglas
iptables -F
iptables -t nat -F
iptables -X 2>/dev/null || true

# Políticas básicas
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

# Reglas básicas de forwarding
iptables -A FORWARD -i enp1s0 -o tun0 -j ACCEPT
iptables -A FORWARD -i tun0 -o enp1s0 -m state --state RELATED,ESTABLISHED -j ACCEPT

# NAT para VPN
iptables -t nat -A POSTROUTING -o tun0 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 192.168.53.0/24 -o tun0 -j MASQUERADE

# Reglas específicas para redes corporativas
iptables -I FORWARD 1 -s 192.168.53.0/24 -d 10.180.0.0/16 -j ACCEPT
iptables -I FORWARD 2 -s 192.168.53.0/24 -d 10.182.0.0/16 -j ACCEPT
iptables -I FORWARD 3 -s 192.168.53.0/24 -d 10.184.0.0/16 -j ACCEPT
iptables -I FORWARD 4 -s 192.168.53.0/24 -d 10.186.0.0/16 -j ACCEPT

# ===== 5.1. REGLAS CRÍTICAS MSS/MTU (SOLUCIÓN SSL) =====
echo "🔧 Configurando MSS/MTU para SSL..."
# CRÍTICO: Sin esto, SSL/HTTPS falla desde Aurin
iptables -t mangle -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
iptables -t mangle -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --set-mss 1200

# Guardar reglas
iptables-save > /etc/iptables/rules.v4

# ===== 6. SERVICIO DE MONITOR VPN =====
echo "👁️ Configurando monitor VPN..."
cat > /usr/local/bin/vpn-monitor.sh << 'EOF'
#!/bin/bash
# Monitor que detecta VPN y reconfigura DNS automáticamente

LAST_VPN_STATE=false
LOG_FILE="/var/log/vpn-monitor.log"

log_message() {
    echo "$(date): $1" >> "$LOG_FILE"
    echo "$1"
}

while true; do
    if ip link show tun0 >/dev/null 2>&1; then
        if [ "$LAST_VPN_STATE" = false ]; then
            log_message "✅ VPN detectada, reconfigurano DNS..."
            
            # Obtener DNS de la VPN (si están disponibles)
            if systemctl is-active systemd-resolved >/dev/null 2>&1; then
                # Si systemd-resolved está activo, obtener DNS de tun0
                VPN_DNS=$(resolvectl dns tun0 2>/dev/null | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' | head -2)
                if [ -n "$VPN_DNS" ]; then
                    log_message "📡 DNS VPN detectados: $VPN_DNS"
                    # Actualizar dnsmasq.conf con los DNS reales
                    sed -i '/^server=/d' /etc/dnsmasq.conf
                    echo "$VPN_DNS" | while read dns; do
                        echo "server=$dns" >> /etc/dnsmasq.conf
                    done
                    systemctl restart dnsmasq
                fi
            fi
            
            LAST_VPN_STATE=true
            log_message "✅ Configuración VPN aplicada"
        fi
    else
        if [ "$LAST_VPN_STATE" = true ]; then
            log_message "❌ VPN desconectada"
            LAST_VPN_STATE=false
        fi
    fi
    
    sleep 5
done
EOF

chmod +x /usr/local/bin/vpn-monitor.sh

# ===== 7. SERVICIO SYSTEMD =====
echo "⚙️ Configurando servicios..."
cat > /etc/systemd/system/vpn-monitor.service << 'EOF'
[Unit]
Description=VPN Monitor Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/vpn-monitor.sh
Restart=always
RestartSec=10
User=root

[Install]
WantedBy=multi-user.target
EOF

# ===== 8. DESHABILITAR SERVICIOS CONFLICTIVOS =====
echo "🛑 Deshabilitando servicios conflictivos..."
systemctl stop systemd-resolved 2>/dev/null || true
systemctl disable systemd-resolved 2>/dev/null || true

# ===== 9. SCRIPTS DE UTILIDAD =====
echo "🔧 Creando scripts de utilidad..."
cat > /usr/local/bin/vpn-status.sh << 'EOF'
#!/bin/bash
echo "=== ESTADO VPN VM ==="
echo "Fecha: $(date)"
echo ""

echo "Red:"
ip addr show enp1s0 | grep inet || echo "❌ Sin IP"
echo ""

echo "VPN:"
if ip link show tun0 >/dev/null 2>&1; then
    echo "✅ tun0 activo: $(ip addr show tun0 | grep 'inet ' | awk '{print $2}')"
    echo "   Ruta VPN: $(ip route | grep tun0 | head -1)"
else
    echo "❌ tun0 no encontrado"
fi
echo ""

echo "DNS:"
echo "✅ dnsmasq: $(systemctl is-active dnsmasq 2>/dev/null)"
echo "✅ resolv.conf: $(head -3 /etc/resolv.conf | grep nameserver)"
echo ""

echo "Test conectividad:"
echo "🌐 Internet: $(ping -c 1 8.8.8.8 >/dev/null 2>&1 && echo 'OK' || echo 'FAIL')"
echo "🏢 Corporativo: $(ping -c 1 10.180.49.66 >/dev/null 2>&1 && echo 'OK' || echo 'FAIL')"
echo "🔍 DNS corporativo: $(dig +short bitbucket.vocento.com @127.0.0.1 2>/dev/null || echo 'FAIL')"

echo ""
echo "Logs recientes:"
tail -5 /var/log/vpn-monitor.log 2>/dev/null || echo "Sin logs de monitor"
EOF

chmod +x /usr/local/bin/vpn-status.sh

# ===== 10. FINALIZAR =====
echo "🔄 Aplicando configuración..."
netplan apply
systemctl enable dnsmasq
systemctl restart dnsmasq
systemctl enable vpn-monitor
systemctl start vpn-monitor

# Crear alias útiles
cat >> /root/.bashrc << 'EOF'

# Aliases VPN
alias vpn-status='/usr/local/bin/vpn-status.sh'
alias vpn-logs='tail -f /var/log/vpn-monitor.log'
alias vpn-restart='systemctl restart vpn-monitor dnsmasq'
EOF

echo ""
echo "🎉 ========================================="
echo "   CONFIGURACIÓN VPN COMPLETADA"
echo "========================================="
echo ""
echo "📋 COMANDOS ÚTILES:"
echo "   vpn-status     - Ver estado completo"
echo "   vpn-logs       - Ver logs en tiempo real"  
echo "   vpn-restart    - Reiniciar servicios"
echo ""
echo "📁 PASOS SIGUIENTES:"
echo "   1. Conectar VPN Pulse Secure manualmente"
echo "   2. Ejecutar: vpn-status"
echo "   3. Verificar desde Aurin: ping 10.180.49.66"
echo ""
echo "💾 Backup guardado en: $BACKUP_DIR"
echo "🚀 ¡VM lista para funcionar!"
