#!/usr/bin/env nix-shell
#!nix-shell -p libvirt qemu qemu-utils util-linux -i bash

# Configuración
BACKUP_ROOT="/storage/vm"
DATE=$(date +%Y%m%d_%H%M%S)

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Función para validar permisos root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}Este script necesita permisos de root${NC}"
        exit 1
    fi
}

# Función para hacer backup de una VM
backup_vm() {
    local VM_NAME=$1
    local SNAPSHOT_NAME=$2
    local BACKUP_DIR="${BACKUP_ROOT}/${SNAPSHOT_NAME}"

    echo -e "${GREEN}Iniciando backup de VM: ${VM_NAME} con snapshot: ${SNAPSHOT_NAME}${NC}"

    # Verificar si la VM está corriendo
    if virsh domstate "${VM_NAME}" | grep -q "running"; then
        echo -e "${YELLOW}ADVERTENCIA: La VM está corriendo. Se recomienda apagarla antes del backup.${NC}"
        read -p "¿Continuar anyway? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi

    # Crear directorio de backup
    mkdir -p "${BACKUP_DIR}"

    # Obtener información del disco
    local DISK_PATH=$(virsh domblklist "${VM_NAME}" | grep vda | awk '{print $2}')
    if [ -z "${DISK_PATH}" ]; then
        echo -e "${RED}Error: No se puede encontrar el disco para ${VM_NAME}${NC}"
        return 1
    fi

    echo "Guardando configuración XML..."
    virsh dumpxml "${VM_NAME}" > "${BACKUP_DIR}/${VM_NAME}_config.xml"

    echo "Copiando disco virtual..."
    cp "${DISK_PATH}" "${BACKUP_DIR}/${VM_NAME}_disk.qcow2"

    # Si existe un snapshot, guardar su configuración
    if virsh snapshot-list "${VM_NAME}" | grep -q "${SNAPSHOT_NAME}"; then
        echo "Guardando configuración del snapshot..."
        virsh snapshot-dumpxml "${VM_NAME}" "${SNAPSHOT_NAME}" > "${BACKUP_DIR}/${SNAPSHOT_NAME}_snapshot.xml"
    fi

    echo -e "${GREEN}Backup completado en: ${BACKUP_DIR}${NC}"
    echo "Archivos guardados:"
    ls -lh "${BACKUP_DIR}"
}

# Función para restaurar una VM desde backup
restore_vm() {
    local VM_NAME=$1
    local SNAPSHOT_NAME=$2
    local BACKUP_DIR="${BACKUP_ROOT}/${SNAPSHOT_NAME}"

    echo -e "${GREEN}Iniciando restauración de VM: ${VM_NAME} desde snapshot: ${SNAPSHOT_NAME}${NC}"

    # Verificar que existe el backup
    if [ ! -d "${BACKUP_DIR}" ]; then
        echo -e "${RED}Error: No se encuentra el directorio de backup: ${BACKUP_DIR}${NC}"
        return 1
    fi

    # Verificar archivos necesarios
    if [ ! -f "${BACKUP_DIR}/${VM_NAME}_config.xml" ] || [ ! -f "${BACKUP_DIR}/${VM_NAME}_disk.qcow2" ]; then
        echo -e "${RED}Error: Faltan archivos de backup necesarios${NC}"
        return 1
    fi

    # Si la VM existe, preguntar antes de sobrescribir
    if virsh list --all | grep -q "${VM_NAME}"; then
        echo -e "${YELLOW}ADVERTENCIA: La VM ${VM_NAME} ya existe${NC}"
        read -p "¿Desea eliminarla y restaurar desde el backup? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 1
        fi
        virsh destroy "${VM_NAME}" 2>/dev/null
        virsh undefine "${VM_NAME}" --remove-all-storage
    fi

    # Restaurar disco
    local IMAGES_DIR="/var/lib/libvirt/images"
    echo "Restaurando disco virtual..."
    cp "${BACKUP_DIR}/${VM_NAME}_disk.qcow2" "${IMAGES_DIR}/${VM_NAME}.qcow2"

    # Restaurar configuración
    echo "Restaurando configuración..."
    virsh define "${BACKUP_DIR}/${VM_NAME}_config.xml"

    # Restaurar snapshot si existe
    if [ -f "${BACKUP_DIR}/${SNAPSHOT_NAME}_snapshot.xml" ]; then
        echo "Restaurando snapshot..."
        virsh snapshot-create "${VM_NAME}" "${BACKUP_DIR}/${SNAPSHOT_NAME}_snapshot.xml"
    fi

    echo -e "${GREEN}Restauración completada${NC}"
}

# Función de ayuda
show_help() {
    echo "Uso: $0 [backup|restore] <nombre-vm> <nombre-snapshot>"
    echo
    echo "Comandos:"
    echo "  backup   - Crear backup de una VM"
    echo "  restore  - Restaurar una VM desde backup"
    echo
    echo "Ejemplo:"
    echo "  $0 backup ubuntu22.04 vpn-working"
    echo "  $0 restore ubuntu22.04 vpn-working"
}

# Main
# Verificar argumentos
if [ $# -ne 3 ]; then
    show_help
    exit 1
fi

check_root

ACTION=$1
VM_NAME=$2
SNAPSHOT_NAME=$3

case "${ACTION}" in
    backup)
        if ! virsh list --all | grep -q "${VM_NAME}"; then
            echo -e "${RED}Error: La VM ${VM_NAME} no existe${NC}"
            exit 1
        fi
        backup_vm "${VM_NAME}" "${SNAPSHOT_NAME}"
        ;;
    restore)
        restore_vm "${VM_NAME}" "${SNAPSHOT_NAME}"
        ;;
    *)
        echo -e "${RED}Error: Acción inválida${NC}"
        show_help
        exit 1
        ;;
esac
