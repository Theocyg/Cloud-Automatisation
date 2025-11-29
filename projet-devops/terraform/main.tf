provider "google" {
  project     = "cloud-automatisation"
  region      = "europe-west1"
  zone        = "europe-west1-b"
  credentials = file("../gcp-creds.json")
}

resource "google_compute_project_metadata" "ssh_keys" {
  metadata = {
    ssh-keys = "Theocyg:${file("~/.ssh/id_ed25519.pub") }"
  }
}

resource "google_compute_network" "vpc_network" {
  name                    = "devops-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "devops-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = "europe-west1"
  network       = google_compute_network.vpc_network.id
}

resource "google_compute_firewall" "allow-ssh" {
  name    = "allow-ssh"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh-enabled"]
}

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

resource "google_compute_firewall" "allow-app-internal" {
  name    = "allow-app-internal"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["3000"]
  }

  source_tags = ["web-server"]
  target_tags = ["app-server"]
}

resource "google_compute_instance" "load_balancer" {
  name         = "vm-load-balancer"
  machine_type = "e2-micro"
  zone         = "europe-west1-b"
  tags         = ["ssh-enabled", "load-balancer"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id
    access_config {}
  }
}

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

resource "google_compute_firewall" "allow-db-internal" {
  name    = "allow-db-internal"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["5432"]
  }

  source_tags = ["app-server", "db-server"]
  target_tags = ["db-server"]
}
