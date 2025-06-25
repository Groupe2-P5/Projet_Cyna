#!/bin/bash

# Répertoire local de sauvegarde
BACKUP_DIR="/var/backups"
mkdir -p "$BACKUP_DIR"

# Détails du serveur distant
REMOTE_SERVER="user@192.168.50.10"
REMOTE_DIR="/home/user/backup/zabbix"

# Fichiers à sauvegarder
ZABBIX_CONF="/etc/zabbix/zabbix_server.conf"
ZABBIX_DB_DUMP="${BACKUP_DIR}/zabbix_db.sql"
BACKUP_NAME="zabbix.tar.gz"

# Infos base de données PostgreSQL
DB_USER="zabbix"
DB_PASS="Z@bbixP455w0RD"
DB_NAME="zabbix"
DB_HOST="localhost"

echo "[+] Sauvegarde de la base de données Zabbix (PostgreSQL)..."
PGPASSWORD="$DB_PASS" pg_dump -U "$DB_USER" -h "$DB_HOST" "$DB_NAME" > "$ZABBIX_DB_DUMP"

if [ $? -ne 0 ]; then
    echo "[!] Échec du dump de la base de données"
    exit 1
fi

echo "[+] Création de l’archive..."
tar --warning=no-file-changed -czf "${BACKUP_DIR}/${BACKUP_NAME}" "$ZABBIX_CONF" "$ZABBIX_DB_DUMP"

if [ $? -ne 0 ]; then
    echo "[!] Échec de la création de l'archive"
    exit 1
fi

echo "[+] Envoi de la sauvegarde vers le serveur distant..."
rsync -avz --delete "${BACKUP_DIR}/${BACKUP_NAME}" "$REMOTE_SERVER:$REMOTE_DIR"

if [ $? -ne 0 ]; then
    echo "[!] Échec de l'envoi vers le serveur distant"
    exit 1
fi

echo "[+] Suppression du dump SQL temporaire..."
rm -f "$ZABBIX_DB_DUMP"

echo "[+] Suppression des anciennes sauvegardes locales (plus de 1 jour)..."
find "$BACKUP_DIR" -type f -name "zabbix_*.tar.gz" -mtime +1 -delete

echo "[✓] Sauvegarde Zabbix terminée avec succès."