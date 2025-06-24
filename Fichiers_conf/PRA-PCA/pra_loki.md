# PLAN DE REPRISE D’ACTIVITÉ (PRA) – SERVICE LOKI

## 1. Introduction

### Objectif
Ce document décrit les procédures à suivre en cas d’incident critique impactant le service Loki, utilisé pour la centralisation des logs. L’objectif est d’assurer une reprise rapide du service avec une perte de données inférieure à 24 heures.

### Contexte
Loki est un composant essentiel de la stack de supervision. Il collecte, stocke et rend consultables les logs systèmes et applicatifs via Grafana. Il est interconnecté avec :

- **Promtail** : agent de collecte des logs  
- **Grafana** : plateforme de visualisation  

Sa disponibilité est cruciale pour l’observabilité des systèmes.

---

## 2. Scénarios de sinistre couverts

Ce PRA couvre les situations suivantes :

- Crash du service Loki  
- Corruption du répertoire de stockage  
- Perte de données (accidentelle ou corruption)  
- Perte ou altération du fichier de configuration  
- Restauration complète sur une nouvelle machine  
- Défaillance matérielle (disque ou serveur Loki)  

---

## 3. Prérequis techniques

| Élément                | Détail                                                                 |
|------------------------|------------------------------------------------------------------------|
| Répertoire de stockage | `/var/lib/loki/` : contient les données de Loki                        |
| Fichier de configuration | `/etc/loki/config.yaml` : configuration principale                   |
| Binaire Loki           | `/usr/bin/loki` ou installation manuelle                               |
| Sauvegarde automatisée | Via `rsync` sécurisé vers `192.168.x.x:/backups/loki/` (via clé SSH)   |
| Accès sudo             | Requis sur la machine cible                                             |
| Connexion réseau       | Accès au serveur de sauvegarde nécessaire                               |
| Services associés      | Promtail, Grafana                                                       |

---

## 4. Procédures de restauration

### 4.1 Crash simple du service

Vérifier l’état du service :

```bash
sudo journalctl -xeu loki
```

Identifier la cause via les logs :

```bash
sudo journalctl -xeu loki
```

Redémarrer le service :

```bash
sudo systemctl restart loki
```

*Si l’erreur persiste, appliquer les scénarios 4.2 ou 4.3.*

---

### 4.2 Corruption ou perte de données

Arrêter Loki :

```bash
sudo systemctl stop loki
```

Restaurer les données depuis la sauvegarde la plus récente :

```bash
rsync -avz -e "ssh -i /chemin/vers/cle" user@192.168.x.x:/backups/loki/ /var/lib/loki/
```

Réajuster les droits :

```bash
sudo chown -R loki:loki /var/lib/loki
```

Redémarrer Loki :

```bash
sudo systemctl start loki
```

---

### 4.3 Reprise sur un nouveau serveur

Télécharger et installer Loki manuellement :

```bash
wget https://github.com/grafana/loki/releases/download/vX.Y.Z/loki-linux-amd64.zip
unzip loki-linux-amd64.zip
sudo mv loki-linux-amd64 /usr/bin/loki
sudo chmod +x /usr/bin/loki
```

Recréer les répertoires de configuration et de données :

```bash
sudo mkdir -p /etc/loki /var/lib/loki
```

Restaurer la configuration :

```bash
scp -i /chemin/vers/cle user@192.168.x.y:/etc/loki/config.yaml /etc/loki/
```

Restaurer les données comme en 4.2.

Créer un service systemd si besoin (`/etc/systemd/system/loki.service`)  
*(utiliser le modèle officiel de la documentation Loki)*

Activer et démarrer le service :

```bash
sudo systemctl daemon-reexec
sudo systemctl enable --now loki
```

---

## 5. Vérifications post-restauration

- Vérifier la connectivité depuis Grafana  
- Vérifier les dashboards et logs visibles  
- Vérifier le bon fonctionnement de Promtail :

```bash
tail -f /var/log/promtail.log
```

- Vérifier les logs Loki :

```bash
journalctl -u loki
```

- Tester la disponibilité locale :

```bash
curl http://localhost:3100/metrics
```

---

## 6. Checklist de reprise

### ✅ Avant incident

- Sauvegardes automatisées quotidiennes testées  
- Fichiers de configuration versionnés dans Gitea  
- Test de restauration mensuel (recommandé)  

### ⚠️ Pendant incident

- Identifier le type d’incident : crash, perte, corruption...  
- Appliquer la procédure appropriée  

### ✅ Après incident

- Contrôle du retour à la normale  
- Vérification dans Grafana et Promtail  
- Documentation de l’incident et des actions entreprises  

---

## 7. Annexes

### Exemple de crontab de sauvegarde

```bash
0 3 * * * rsync -avz -e "ssh -i /chemin/vers/cle" /var/lib/loki/ user@192.168.x.x:/backups/loki/$(date +\%F)/
```

### Rotation recommandée (supprimer les sauvegardes de plus de 14 jours)

```bash
find /backups/loki/ -type d -mtime +14 -exec rm -rf {} \;
```

### Commandes utiles

```bash
systemctl status loki
journalctl -xeu loki
curl http://localhost:3100/ready
```

---

**Document à usage interne – Maintenu par l’équipe observabilité / supervision**