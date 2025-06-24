# Plan de Reprise d’Activité – Sécurité SSH & Bruteforce

## Contexte

Dans le cadre du projet Webzine DI1-P4, l’infrastructure repose sur des machines virtuelles hébergeant divers services critiques (Gitea, Zabbix, PostgreSQL, Webzine...). Ces services sont accessibles à distance pour l'administration (SSH). 

L'accès SSH, bien que pratique, constitue une porte d’entrée privilégiée pour les attaques par brute-force visant à deviner les identifiants d’accès. Si l’attaquant parvient à accéder au serveur, il peut compromettre les données, intercepter les échanges, ou encore désactiver des services.

Pour éviter cela, des dispositifs préventifs sont mis en place (pare-feu, Fail2Ban, AppArmor, clés SSH, audit de logs, etc.). Le PRA ci-dessous vise à réagir rapidement à une attaque réussie ou suspectée, tout en permettant une reprise d’activité sécurisée.

---

## Objectif du PRA

L’objectif principal est d'assurer une reprise de l’activité rapide et sécurisée après une attaque sur le service SSH. Ce plan vise à :

- Réagir efficacement à une tentative ou une compromission SSH
- Isoler le système touché pour éviter toute propagation
- Analyser les traces pour comprendre l’incident
- Restaurer l’intégrité des services essentiels
- Réimplémenter les accès de manière plus robuste
- Prévoir un plan d’amélioration continue post-incident

---

## Détection de l’incident

Plusieurs signaux permettent de détecter une tentative de brute-force ou une compromission :

- **Alertes Zabbix** : nombre élevé de tentatives SSH sur une période courte
- **Logs `/var/log/auth.log`** : présence d’IP inconnues, tentatives multiples de login
- **Notifications Fail2Ban** : bannissements répétés ou récurrents d’adresses IP
- **Tableau de bord Grafana** : pics d’activité inhabituels, connexions SSH hors plage horaire
- **Symptômes système** : montée en charge CPU anormale, process suspects

---

## Procédure de reprise

### Étape 1 – Isolation du serveur

Isoler le serveur compromis du reste du réseau :
- **Désactivation de la carte réseau** :
```bash
ip link set eth0 down #eth0 est un exemple cela dépend du nom de la carte réseau
```
Pour voir le nom de la carte réseau tapez :
``` bash
ip a
```
- **Blocage via pare-feu** :
```bash
nft add rule inet filter input ip saddr IP_SUSPECT drop
```

### Étape 2 – Analyse des indices d'intrusion

#### Accès aux logs :
```bash
less /var/log/auth.log
journalctl -u ssh
```

#### Vérifier les IP bannies :
```bash
fail2ban-client status sshd
```

#### Liste des processus réseau actifs :
```bash
netstat -tulnp
lsof -i :22
```

#### Rechercher les connexions persistantes :
```bash
who
w
```

#### Liste des fichiers récents ou modifiés :
```bash
find / -type f -mmin -60
```

### Étape 3 – Restauration du système

**Scénario A : tentative échouée**
- Réinitialiser les bans Fail2Ban :
```bash
fail2ban-client unban --all
```
- Ajouter les IP suspectes :
```bash
echo 'sshd: IP_SUSPECT' >> /etc/hosts.deny
```

**Scénario B : serveur compromis**
- Restaurer un snapshot : *(via hyperviseur ou script)*
- Vérifier services :
```bash
systemctl status zabbix-agent gitea postgresql
```

### Étape 4 – Réactivation des services

- Redémarrer Zabbix agent :
```bash
systemctl restart zabbix-agent
```
- Réactiver l’interface réseau :
```bash
ip link set eth0 up
```
- Test de connexion sécurisée :
```bash
ssh -i ~/.ssh/id_rsa admin@<IP_SERVER>
```

### Étape 5 – Renforcement post-incident

- **Changer les clés SSH** :
```bash
ssh-keygen -t ed25519 -C "nouvelle_clé"
```
- Modifier sshd_config :
```bash
nano /etc/ssh/sshd_config
```
```bash
PermitRootLogin no 
PasswordAuthentication no
MaxAuthTries 3
AllowUsers admin1 admin2 # Mettre les noms des utilisateurs que vous voulez qu'ils puissent se connecter en ssh.
LogLevel VERBOSE
```
- Redémarrer SSH :
```bash
systemctl restart ssh
```

- Configurer Fail2Ban :
```bash
nano /etc/fail2ban/jail.local
```
```ini
[sshd]
enabled = true
maxretry = 3
findtime = 600
bantime = 3600
```

- Recharger firewall :
```bash
nft list ruleset
systemctl reload nftables
```

### Étape 6 – Vérification

- Tester une attaque :
```bash
hydra -l root -P /usr/share/wordlists/rockyou.txt ssh://<IP> # IP corespond à l'IP du serveur que vous voulez tester
```
- Observer la réponse de Fail2Ban & alertes Zabbix

---


