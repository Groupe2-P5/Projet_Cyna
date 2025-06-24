## Installation GLPI

### Préparez la machine à recevoir GLPI

Dans ce cycle d’installation, nous allons utiliser une **machine virtuelle Debian 12** montée sur un Proxmox. De plus, l’installation d’un serveur LAMP sera nécessaire.

Voici les propriétés de la machine virtuelle que nous utilisons :
- 1024 MO de RAM ;
- 8 GO de disque dur.
***
### Installation des paquets nécessaires

```bash
apt-get install apache2 php libapache2-mod-php # installation server web
apt-get install php-imap php-ldap php-curl php-xmlrpc php-gd php-mysql php-cas # installation language web
apt-get install mariadb-server # installation base de données
mysql_secure_installation # sécurisation
```
(Mettre tout en yes pour l'installation de la sécurité)

### Installation de modules complémentaires
```bash
apt-get install apcupsd php-apcu
```
### Redémarrer les services
```bash
/etc/init.d/apache2 restart
/etc/init.d/mariadb restart
```
Ensuite, on créer la base de données: 
```bash
mysql -u root -p "mdp root machine"
MariaDB [(none)]> create database glpidb;
MariaDB [(none)]> grant all privileges on glpidb.* to glpiuser@localhost identified by "V26zyF";
MariaDB [(none)]> quit
```
Pour plus de simplicité dans l’avenir, on installera **phpMyAdmin**, qui va nous permettre de gérer la base de données en interface graphique :
```bash
apt-get install phpmyadmin
```
Quand la commade est lancée on choisit Apache2 et répondre NON à “créer la base avec db_common".
***
### Installer GLPI

Commencer par se déplacer dans le dossier : `cd /usr/src/`
Une première installation en ligne de commande nous permet de récupérer les paquets GLPI
```bash
wget https://github.com/glpi-project/glpi/releases/download/10.0.18/glpi-10.0.18.tgz # dernière version à ce jour vérifier dans les dépôts si ça n'a pas changé
tar -xvzf glpi-10.0.18.tgz -C /var/www/html
chown -R www-data /var/www/html/glpi/
```
Une fois l'installation faite, on se connecte à la page web:
`http://<@IP_vm_glpi>/glpi/`

Sur l'interface: 
- Choisir la langue
- Accepter la licence
- Puis installer le service

Sur le menu suivant, nous vérifierons que tous les paquets sont correctement installés.
Ici, il en manque une:

![image.png](/.attachments/image-f43f9203-52bf-40cc-b597-09ceefe5a7ed.png)

Si un paquet n'est pas validé, c’est qu’il manque une dépendance. Le plus souvent, ce problème se règle en tapant le nom de l’extension précédé par “php-”
Exemples :
- S’il manque l’extension CAS, la commande est la suivante →  `apt-get install php-cas`
- S’il manque l’extension CURL, la commande sera →  `apt-get install php-curl`
    
L'extension intl ne s'étant pas faite dans notre cas, la commande à passé est donc la suivante: `apt-get install php-intl`
Puis on reboot la machine.

Ensuite on se connecte à notre base de données. Sur cette fenêtre, nous allons associer GLPI à sa base de données créée précédemment sur MariaDB.

![image.png](/.attachments/image-9ec50bb9-9b97-47aa-9db9-b12c2a8afeb7.png)

On nous demande ensuite quel base on veut utiliser. Ici on utilise celle précédemment faite
Une fois fait, surtout attendre l’initialisation de la base. Cette opération peut prendre du temps. Ne pas cliquer plusieurs fois sur [Continuer], au risque de créer deux fois la base de données !

Pour se connecter par défaut:
Login: **glpi**
MDP: **glpi**
***
## Sources
https://openclassrooms.com/fr/courses/1730516-gerez-votre-parc-informatique-avec-ocs-inventory/5993816-installez-votre-serveur-glpi