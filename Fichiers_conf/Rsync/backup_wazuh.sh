#!/bin/bash

# Répertoire local de sauvegarde
BACKUP_DIR="/var/backups"

# Détails du serveur distant
REMOTE_SERVER="user@192.168.50.10"
REMOTE_DIR="/home/user/backup/wazuh"

# Nom de la sauvegarde (fixe)
BACKUP_NAME="wazuh.tar.gz"
ARCHIVE_PATH="${BACKUP_DIR}/${BACKUP_NAME}"

# Répertoires Wazuh à sauvegarder
WAZUH_DIRS=(
  /etc/wazuh-dashboard
  /etc/wazuh-indexer
  /var/ossec/etc
  /var/log/wazuh-indexer
)

# Créer le répertoire local s'il n'existe pas
mkdir -p "$BACKUP_DIR"

# Supprimer l'ancienne archive avant de la recréer
[ -f "$ARCHIVE_PATH" ] && rm -f "$ARCHIVE_PATH"

echo "[+] Sauvegarde de Wazuh..."
tar --warning=no-file-changed -czf "$ARCHIVE_PATH" "${WAZUH_DIRS[@]}"
if [ $? -ne 0 ]; then
    echo "[!] Échec de la création de l'archive"
    exit 1
fi

echo "[+] Envoi de la sauvegarde vers le serveur distant..."
rsync -avz "$ARCHIVE_PATH" "$REMOTE_SERVER:$REMOTE_DIR"
if [ $? -ne 0 ]; then
    echo "[!] Échec de l'envoi vers le serveur distant"
    exit 1
fi

echo "[✓] Sauvegarde Wazuh terminée avec succès."