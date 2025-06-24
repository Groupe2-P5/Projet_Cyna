#!/bin/bash

# Répertoire local de sauvegarde
BACKUP_DIR="/var/backups"

# Détails du serveur distant
REMOTE_SERVER="user@192.168.50.10"
REMOTE_DIR="/home/user/backup/grafana"

# Nom de la sauvegarde avec date
BACKUP_NAME="grafana.tar.gz"

# Fichier Zabbix à sauvegarder
GRAFANA_CONF=(/etc/grafana /etc/loki /var/lib/grafana /var/lib/loki)

# Créer le répertoire local s'il n'existe pas
mkdir -p "$BACKUP_DIR"

echo "[+] Sauvegarde de Grafana..."
tar --warning=no-file-changed -czf "${BACKUP_DIR}/${BACKUP_NAME}" "${GRAFANA_CONF[@]}"

if [ $? -ne 0 ]; then
    echo "[!] Échec de la création de l'archive"
    exit 1
fi

echo "[+] Envoi au serveur distant..."
rsync -avz --delete "${BACKUP_DIR}/${BACKUP_NAME}" "$REMOTE_SERVER:$REMOTE_DIR"

if [ $? -ne 0 ]; then
    echo "[!] Échec de l'envoi vers le serveur distant"
    exit 1
fi

echo "[+] Suppression des anciennes sauvegardes locales (plus de 1 jour)..."
find "$BACKUP_DIR" -type f -name "grafana_*.tar.gz" -mtime +1 -delete

echo "[✓] Sauvegarde terminée avec succès."