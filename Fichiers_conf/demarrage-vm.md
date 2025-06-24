  

# Installation de Zabbix mono-server avec postgres

#### Table des matières

1. [Création du serveur Zabbix mode unifié](#création-du-serveur-zabbix-mode-unifié)

2. [Création hôte et éléments](#création-hôte-et-éléments)

  

## Création du serveur Zabbix mode unifié

**Créez un point de contrôle au préablable (snapshot)**  

  

Pensez à changer votre hostname local :

```bash

nano /etc/hostname

zabbixserver

```

>Note : Pensez a éditer le `hostname` dans le fichier `/etc/hosts` également.  

  

NTP client : Installez Chrony :

```bash

apt install chrony -y

```

  

Activez et démarrez Chrony au démarrage de la machine :

```bash

systemctl enable chrony --now

```

  

Lister les sources disponibles et utilisées par Chrony :

```bash

chronyc sources

```

  

Pensez à vérifier votre `timezone` avec :

```bash

timedatectl status

```

_Note : Si besoin de changer : timedatectl set-timezone Europe/Paris._

  

Installez le service `PostgreSQL` :  

```bash

apt install postgresql-15 postgresql-client-15 -y

```

Lancez le cluster PG avec la commande suivante et controlez son lancement, puis, automatisez son lancement automatique à chaque redemarrage de la machine:

```bash

pg_ctlcluster 15 main start

systemctl status postgresql@15-main.service

systemctl enable postgresql

```

Pour des raisons de sécurités, changez le mot de passe du compte `postgres` sur le SGBD lui même :

```bash

su postgres

psql

```

```sql

ALTER USER postgres PASSWORD 'P@ssw0rd';

\q

```

Quittez le compte `postgres` et revenez en `root`

  

Installez Zabbix :

```bash

wget https://repo.zabbix.com/zabbix/7.0/debian/pool/main/z/zabbix-release/zabbix-release_7.0-2+debian12_all.deb

dpkg -i zabbix-release_7.0-2+debian12_all.deb

apt update

apt install sudo zabbix-server-pgsql zabbix-sql-scripts

```

  

Créez la base de données :

>Note : A la demande mot de passe sur le compte, j utilise le mot de passe : Z@bbixP455w0RD

```bash

sudo -u postgres createuser --pwprompt zabbix

sudo -u postgres createdb -O zabbix zabbix

```

Puis on importe le schéma de la base :

```bash

zcat /usr/share/zabbix-sql-scripts/postgresql/server.sql.gz | sudo -u zabbix psql zabbix

```

Installez le reste des dépendances (front web) :  

```bash

apt install zabbix-frontend-php php8.2-pgsql zabbix-apache-conf

```

  

Editez le fichier de configuration `Zabbix Server` pour ajouter le mot de passe de la BDD :

```bash

nano /etc/zabbix/zabbix_server.conf

```

```bash

DBPassword=Z@bbixP455w0RD

```

Rechargez les services pour appliquer la nouvelle configuration :

```bash

systemctl restart zabbix-server apache2

systemctl enable apache2 zabbix-server

```

Editez les `timezones` dans le fichier suivant pour rajouter `Europe/Paris`.

```bash

nano /etc/php/8.2/apache2/php.ini

```

```php

[Date]

; Defines the default timezone used by the date functions

; http://php.net/date.timezone

date.timezone = Europe/Paris

```

  

Puis accedez à l'interface web du serveur Zabbix :  

http://{IP Zabbix Server à remplacer}/zabbix

  

Sur l'étape `Configure DB connection`, ajoutez le mot de passe du compte zabbix : `Z@bbixP455w0RD`  en laissant le reste par défaut.    

Finalisez la configuration.  

_Notez que l'ensemble des informations de configuration du front web sont accessibles ici `/usr/share/zabbix/conf/zabbix.conf.php`._

  

Pour vous connecter, utilisez les identifiants par défaut : `Admin / zabbix`

**Créez un point de contrôle au préablable (snapshot)**

***

## Création hôte et éléments

#### 1. Hôtes

1.  Aller dans **collecte de données > Hôtes**
    
2.  Cliquer sur **Créer un hôte**
    
3.  Remplir :
    *   **Nom de l’hôte** : `pfSense`, `rsync`, `Wazuh`
        
    *   **Groupes** : ex. `Projet_Cyna`
        
    *   **Agent interface** : IP de l'hôte
        
    *   **Tags** : Ajouter `Composant`, `Vérification`, etc.
        
4.  Cliquer sur **Ajouter**
    

* * *

#### 2. 🔍 Création des éléments (Items)

##### **a. Ping ICMP**

*   **Nom** : `Ping ICMP`
    
*   **Clé** : `icmpping`
    
*   **Type** : `Vérification simple`
    
*   **Intervalle** : `1m`
    
*   **Historique** : `31d`
    
*   **Tendances** : `365d`
    
*   **Tags** : `Vérification: Ping`
    
*   **État** : Activé
    

##### **b. État du service (ex. rsync, wazuh-agent, etc.)**

*   **Nom** : `État du service rsync`
    
*   **Clé** : `service.status

*   **Type** : `agent Zabbix`
    
*   **Intervalle** : `1m`
    
*   **Historique** : `31d`
    
*   **Tendances** : `365d`
    
*   **Tags** : `Vérification: Service`
    
*   **État** : Activé
    

##### **c. Charge CPU**

*   **Nom** : `Charge CPU`
    
*   **Clé** : `system.cpu.load`
    
*   **Type** : `agent Zabbix`
    
*   **Intervalle** : `10s`
    
*   **Historique** : `31d`
    
*   **Tendances** : `365d`
    
*   **Tags** : `Composant: CPU`
    
*   **État** : Activé

****
#### 3. 🔍 Création des déclencheurs
 
* Nom: `ICMP Ping is down on {HOST.NAME}`  
* Sévérité: `Moyen`  
* Expression: `max(/zabbixserver/icmpping,#3)=0`

* Function: `max()`  
* Last of (T): `3 Count`  
* Result: = `0`  
* Allow manual close: `[X]`

