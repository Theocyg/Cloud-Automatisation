# terraform/main.tf

provider "google" {
  project     = "cloud-automatisation"
  region      = "europe-west9"        
  zone        = "europe-west9-a"
  credentials = file("../gcp-creds.json")
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
  region        = "europe-west9"
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
  target_tags   = ["load-balancer"]
}
