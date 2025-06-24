# Active Directory

#### Table des matières

1. [Création de partition de disque](#création-de-partition-de-disque)

2. [Installation AD](#Installation-AD)

3. [Configuration arborescence](#Configuration-arborescence)

4. [Agentless - Preprocessing - Items](#agentless-preprocessing-items)

---
## Création de partition de disque

**Créer un point de contrôle au préablable

Pour une question de bonnes pratiques, on sépare le disque `C:` pour que l'Active Directory ne soit pas accessible directement depuis un utilisateur interne.

Donc pour partitionner un disque:
On va dans **`Panneau de configuration`**>**`Système et sécurité`**>**`Créer et formater des partitions de disque dur`**

![image.png](/.attachments/image-052dbca8-7932-456d-a3d1-d0023ff7d2eb.png)

On réduit l'espace que l'on souhaite, donc ici de 10Go, qui sera attribué pour le partage de fichier. Ce qui reste, donc 20Go sera attribué pour l'Active Directory 

![image.png](/.attachments/image-3e9b72fe-7ad2-426d-bf8c-823ef6b6b318.png)

Les 10Go deviennent non alloués, Donc on créer un volume:
![image.png](/.attachments/image-c4e5d871-22b9-49f6-bfcc-96d48b4cfa59.png)

Les partages de fichiers sont faits de cette manière:
![image.png](/.attachments/image-dbd640d0-5753-496c-95aa-321bbb2c82d7.png)

---

## Installation AD
--- 

## Configuration arborescence

