#!/bin/bash

# Répertoire local de sauvegarde
BACKUP_DIR="/var/backups"
mkdir -p "$BACKUP_DIR"

# Détails du serveur distant
REMOTE_SERVER="user@192.168.50.10"
REMOTE_DIR="/home/user/backup/glpi"

# Noms des fichiers
ARCHIVE_NAME="glpi_files.tar.gz"
SQL_NAME="glpi_db.sql"
ARCHIVE_PATH="${BACKUP_DIR}/${ARCHIVE_NAME}"
SQL_PATH="${BACKUP_DIR}/${SQL_NAME}"

# Dossier GLPI (adapter si ton chemin est différent)
GLPI_WEB_DIR="/var/www/html/glpi"

# Infos base de données (adapter)
DB_USER="glpiuser"
DB_PASS="V26zyF"
DB_NAME="glpidb"

# Suppression des anciennes sauvegardes locales
rm -f "$ARCHIVE_PATH" "$SQL_PATH"

echo "[+] Sauvegarde des fichiers GLPI..."
tar --warning=no-file-changed -czf "$ARCHIVE_PATH" "$GLPI_WEB_DIR"
if [ $? -ne 0 ]; then
    echo "[!] Erreur lors de l'archivage des fichiers"
    exit 1
fi

echo "[+] Sauvegarde de la base de données GLPI..."
mysqldump -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" > "$SQL_PATH"
if [ $? -ne 0 ]; then
    echo "[!] Erreur lors de la sauvegarde MySQL"
    exit 1
fi

echo "[+] Envoi vers le serveur distant..."
rsync -avz "$ARCHIVE_PATH" "$SQL_PATH" "$REMOTE_SERVER:$REMOTE_DIR"
if [ $? -ne 0 ]; then
    echo "[!] Échec de l'envoi vers le serveur distant"
    exit 1
fi

echo "[✓] Sauvegarde GLPI terminée avec succès."