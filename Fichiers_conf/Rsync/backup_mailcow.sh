#!/bin/bash

# Répertoire local de sauvegarde
BACKUP_DIR="/var/backups/mailcow"
MAILCOW_DIR="/opt/mailcow-dockerized"
TMP_MAILCOW_BACKUP="/tmp/mailcow_backup"

# Détails du serveur distant
REMOTE_SERVER="user@192.168.50.10"
REMOTE_DIR="/home/user/backup/mailcow"

# Nom de la sauvegarde avec date
BACKUP_NAME="mailcow.tar.gz"

# Créer le répertoire local s'il n'existe pas
mkdir -p "$BACKUP_DIR"

echo "[+] Sauvegarde de Mailcow..."

# Vérifier que le répertoire Mailcow existe
cd "$MAILCOW_DIR" || { echo "[!] Impossible d'accéder à $MAILCOW_DIR"; exit 1; }

# Nettoyer le répertoire temporaire s'il existe
rm -rf "$TMP_MAILCOW_BACKUP"

# Lancer la sauvegarde Mailcow vers le dossier temporaire
./helper-scripts/backup_and_restore.sh backup all "$TMP_MAILCOW_BACKUP"

if [ $? -ne 0 ]; then
    echo "[!] Échec de la commande de sauvegarde Mailcow"
    exit 1
fi

# Compresser la sauvegarde
echo "[+] Compression de la sauvegarde..."
tar -czf "${BACKUP_DIR}/${BACKUP_NAME}" -C "$TMP_MAILCOW_BACKUP" .

if [ $? -ne 0 ]; then
    echo "[!] Échec de la compression de la sauvegarde"
    rm -rf "$TMP_MAILCOW_BACKUP"
    exit 1
fi

# Nettoyer le répertoire temporaire
rm -rf "$TMP_MAILCOW_BACKUP"

# Envoyer la sauvegarde au serveur distant
echo "[+] Envoi de la sauvegarde vers le serveur distant..."
rsync -avz --delete "${BACKUP_DIR}/${BACKUP_NAME}" "$REMOTE_SERVER:$REMOTE_DIR"

if [ $? -ne 0 ]; then
    echo "[!] Échec de l'envoi vers le serveur distant"
    exit 1
fi

# Supprimer les sauvegardes locales de plus d'un jour
echo "[+] Suppression des anciennes sauvegardes locales (plus de 1 jour)..."
find "$BACKUP_DIR" -type f -name "mailcow_*.tar.gz" -mtime +1 -delete

echo "[✓] Sauvegarde Mailcow terminée avec succès."