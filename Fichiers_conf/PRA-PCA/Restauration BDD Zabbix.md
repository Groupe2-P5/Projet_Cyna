
## 🛠️ **PRA – Restauration de la base de données Zabbix (PostgreSQL)**

### 🧾 **Contexte**

- Objectif : restaurer la base PostgreSQL de Zabbix avec une perte de données < 24h.
- Système : Debian 12.
- Architecture multi-serveurs :
  - `zabbix-server` : moteur de collecte
  - `zabbix-db` : base PostgreSQL
  - `zabbix-frontend` : interface web
- Base de données : PostgreSQL 15.
> Le serveur de base de données Zabbix (PostgreSQL) est accessible à l’adresse IP `192.168.30.11`.



### 📦 **Sauvegarde automatisée (existante)**

**Script de sauvegarde** (`/opt/backupscripts/backup_base_de_donnee_zabbix.sh`) :  
- Utilise `scp` + `sshpass` pour récupérer un dump compressé `*.sql.tar.gz` de la base PostgreSQL distante.
- Stockage dans `/mnt/backups/zabbix/bdd/` avec un sous-répertoire daté.

**Extrait du script** :
```bash
DATE=$(date +"%Y-%m-%d")
scp user@192.168.1.4:/home/user/backup/bdd/zabbix_$DATE.sql.tar.gz /mnt/backups/zabbix/bdd/$DATE
```

**Crontab quotidienne à 11h00 :**
```
0 11 * * * /opt/backupscripts/backup_base_de_donnee_zabbix.sh
```

✅ **Garantie :** une sauvegarde par jour → perte maximale = 24h.



### 🔁 **Procédure de restauration**

#### 1️⃣ **Arrêt des services**
```bash
# Sur zabbix-server
sudo systemctl stop zabbix-server

# Sur zabbix-frontend (si nécessaire)
sudo systemctl stop apache2

# Sur zabbix-db
sudo systemctl stop postgresql
```

#### 2️⃣ **Préparation de la base PostgreSQL**
```bash
sudo -u postgres psql
DROP DATABASE zabbix;
CREATE DATABASE zabbix;
\q
```

#### 3️⃣ **Décompression et restauration**

Sur le serveur de sauvegarde :
```bash
tar -xvzf /mnt/backups/zabbix/bdd/2025-04-20/zabbix_2025-04-20.sql.tar.gz -C /tmp/
```

Sur le serveur `zabbix-db` :
```bash
sudo -u postgres psql zabbix < /tmp/zabbix_2025-04-20.sql
```

#### 4️⃣ **Relance des services**
```bash
sudo systemctl start postgresql
sudo systemctl start zabbix-server
sudo systemctl start apache2
```



### ✅ **Vérifications post-restauration**
- Interface Zabbix disponible via navigateur.
- Logs Zabbix OK :
```bash
journalctl -u zabbix-server -f
```
- Données visibles (graphiques, hôtes actifs)



### 📌 **Bonnes pratiques**
- Tester cette procédure régulièrement (restauration en environnement de préprod).
- Prévoir une supervision du cron via log (`>> /var/log/backup_zabbix_bdd.log 2>&1`)
- Ajouter des notifications en cas d’échec de sauvegarde.
