# Projet Final Cloud Automatisation : Déploiement d'une Application Web 3-Tiers sur GCP

Ce projet automatise le déploiement d'une architecture distribuée, haute disponibilité et sécurisée sur Google Cloud Platform (GCP). Il met en œuvre une chaîne Cloud Automatisation complète respectant les principes de l'**Infrastructure as Code (IaC)** et de l'**Infrastructure Immuable**.

##  Architecture
L'infrastructure est composée de 7 machines virtuelles réparties en 3 tiers, isolées dans un VPC privé :

  * **Load Balancer (Nginx)** : Point d'entrée unique, distribue le trafic vers les serveurs Web.
  * **Tier Web (2 serveurs Nginx)** : Servent le contenu statique et font proxy vers l'API.
  * **Tier App (2 serveurs Flask)** : API Backend (Python) exécutant la logique métier sur le port 3000.
  * **Tier Data (2 serveurs PostgreSQL)** : Base de données relationnelle sur le port 5432.

**Sécurité & Flux :**

  * Seul le Load Balancer est exposé publiquement (Ports 80/443).
  * Flux Web → App autorisé uniquement sur le réseau interne.
  * Flux App → DB autorisé uniquement sur le réseau interne.

-----

## Pré-requis

  * Compte Google Cloud Platform (GCP) avec facturation activée.
  * **Outils installés localement :**
      * [Terraform](https://www.terraform.io/) (Infrastructure)
      * [Packer](https://www.packer.io/) (Images Immuables)
      * [Ansible](https://www.ansible.com/) (Configuration)
      * Google Cloud SDK (`gcloud`)

## 📂 Structure du Projet

```bash
projet-Cloud Automatisation/
├── terraform/      # Provisionnement de l'infrastructure (Réseau, VMs, FW)
├── packer/         # Création des images "Gold" (Web, App, DB)
├── ansible/        # Configuration des serveurs et déploiement de l'app
│   ├── roles/      # Rôles pour LB, Web, App, DB
│   └── inventory/  # Inventaire des hôtes
└── app/            # Code source de l'application (Backend Python)
```

-----

##  Guide de Déploiement

### Étape 1 : Configuration des accès GCP

1.  Placez votre clé de compte de service GCP (`gcp-creds.json`) à la racine du projet.
2.  Assurez-vous que le compte de service a les droits `Compute Admin` et `Service Account User` (J'ai mis full permision pour ne pas me prendre la tete).
 
### Étape 2 : Construction des Images (Packer)

Nous créons des images pré-configurées pour gagner du temps au démarrage.

```bash
cd packer
# Initialisation
packer init .

# Construction des 3 images (Web, App, DB)
packer build -only='*.app-image' .
packer build -only='*.db-image' .
# (L'image web peut être construite via web.pkr.hcl si séparée)
```

*Note : Récupérez les IDs des images créées pour l'étape suivante.*

### Étape 3 : Provisionnement de l'Infrastructure (Terraform)

Déploiement du réseau et des 7 VMs utilisant les images Packer.

```bash
cd ../terraform
# Mettre à jour main.tf avec les IDs des images Packer
nano main.tf 

# Lancer le déploiement
terraform init
terraform apply
```

*Notez les adresses IP affichées en sortie (Outputs).*

### Étape 4 : Configuration et Déploiement (Ansible)

Démarrage des services.

1.  Mettez à jour le fichier `ansible/inventory/hosts.ini` avec les IPs fournies par Terraform.
2.  Lancez le playbook principal :

<!-- end list -->

```bash
cd ../ansible
ansible-playbook -i inventory/hosts.ini deploy.yml
```

-----

## Tests et Validation

### 1\. Test du Load Balancing (Public)

Accédez à l'IP publique du Load Balancer dans un navigateur : `http://<LB_IP>`.

  * Résultat attendu : Affichage de la page "Site En Production". En rafraîchissant, le nom du serveur ("Serveur : vm-web-X") doit changer.

### 2\. Test de la connectivité API (Interne)

Depuis un serveur Web, testez l'appel vers un serveur App :

```bash
curl http://<IP_INTERNE_APP>:3000
# Résultat : {"message": "Backend API is running", ...}
```

### 3\. Test de la Base de Données (Interne)

Depuis un serveur App, testez la connexion PostgreSQL avec ce script Python :

```python
import psycopg2
conn = psycopg2.connect(host='<IP_INTERNE_DB>', user='app_user', password='password123', dbname='my_app_db')
print("Connexion réussie")
conn.close()
```

-----

## 🔧 Troubleshooting (Erreurs que j'ai eu)

**Problème : Quota 'IN\_USE\_ADDRESSES' exceeded.**

  * **Cause :** Vous avez atteint la limite d'IPs publiques (souvent 8 en version gratuite).
  * **Solution :** Lancez `terraform destroy` avant de lancer un build Packer, car Packer a besoin d'une IP temporaire.

**Problème : Erreur Ansible "chmod: invalid mode: 'A+user:postgres:rx:allow'".**

  * **Cause :** Manque du paquet `acl` sur les images Debian minimales.
  * **Solution :** Le rôle Ansible `db_server` installe désormais automatiquement le paquet `acl`.

**Problème : `curl` vers l'App Server échoue (Time out).**

  * **Cause :** Tentative de connexion sur l'IP *Publique* au lieu de l'IP *Privée*.
  * **Solution :** Le firewall n'autorise le port 3000 que sur le réseau interne. Utilisez toujours les IPs en `10.0.1.x`.

-----

## 🧹 Nettoyage

Pour éviter les coûts inutiles, détruisez l'infrastructure après utilisation :

```bash
cd terraform
terraform destroy -auto-approve
```

-----

*Projet réalisé dans le cadre de la formation Cloud Automatisation - 2025*
