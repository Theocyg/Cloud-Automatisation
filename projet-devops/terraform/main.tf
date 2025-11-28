# terraform/main.tf

provider "google" {
  project     = "cloud-automatisation"
  region      = "europe-west1"        
  zone        = "europe-west1-b"
  credentials = file("../gcp-creds.json")
}

# Configuration SSH pour tout le projet
resource "google_compute_project_metadata" "ssh_keys" {
  metadata = {
    # Format: nom_utilisateur:clé_publique
    # Terraform va lire directement le contenu de ton fichier sur ton PC
    ssh-keys = "Theocyg:${file("~/.ssh/id_ed25519.pub")}"
  }
}

# Création du réseau VPC (Réseau Interne des VMs [cite: 34])
resource "google_compute_network" "vpc_network" {
  name                    = "devops-vpc"
  auto_create_subnetworks = false
}

# Création du sous-réseau
resource "google_compute_subnetwork" "subnet" {
  name          = "devops-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = "europe-west1"
  network       = google_compute_network.vpc_network.id
}

# Firewall : Autoriser SSH (Port 22) pour l'Admin 
resource "google_compute_firewall" "allow-ssh" {
  name    = "allow-ssh"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"] # Ou restreindre à ton IP pour plus de sécurité
  target_tags   = ["ssh-enabled"]
}

# Firewall : Autoriser HTTP/HTTPS depuis Internet vers le Load Balancer 
resource "google_compute_firewall" "allow-web-traffic" {
  name    = "allow-web-ingress"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["load-balancer", "web-server"]
}

# --- AJOUT : LES 7 MACHINES VIRTUELLES ---

# 1. Load Balancer (1 VM) - Point d'entrée
resource "google_compute_instance" "load_balancer" {
  name         = "vm-load-balancer"
  machine_type = "e2-micro"
  zone         = "europe-west1-b"
  tags         = ["ssh-enabled", "load-balancer"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11" # On mettra ton image Packer ici plus tard
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id
    access_config {} # IP Publique nécessaire
  }
}

# 2. Web Servers (2 VMs) - Nginx
resource "google_compute_instance" "web_server" {
  count        = 2
  name         = "vm-web-${count.index + 1}"
  machine_type = "e2-micro"
  zone         = "europe-west1-b"
  tags         = ["ssh-enabled", "web-server"]

  boot_disk {
    initialize_params {
      image = "my-web-image-1764339734"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id
    access_config {}
  }
}

# 3. App Servers (2 VMs) - Backend
resource "google_compute_instance" "app_server" {
  count        = 2
  name         = "vm-app-${count.index + 1}"
  machine_type = "e2-micro"
  zone         = "europe-west1-b"
  tags         = ["ssh-enabled", "app-server"]

  boot_disk {
    initialize_params {
      image = "my-app-image-1764341104"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id
    access_config {}
  }
}

# 4. Database Servers (2 VMs) - PostgreSQL
resource "google_compute_instance" "db_server" {
  count        = 2
  name         = "vm-db-${count.index + 1}"
  machine_type = "e2-micro"
  zone         = "europe-west1-b"
  tags         = ["ssh-enabled", "db-server"]

  boot_disk {
    initialize_params {
      image = "my-db-image-1764341392"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id
    access_config {}
  }
}
