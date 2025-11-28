# packer/db.pkr.hcl

source "googlecompute" "db-image" {
  project_id      = var.project_id
  source_image_family = "debian-11"
  zone            = var.zone
  ssh_username    = "packer"
  image_name      = "my-db-image-{{timestamp}}"
  account_file    = "../gcp-creds.json"
}

build {
  sources = ["source.googlecompute.db-image"]

  provisioner "shell" {
    inline = [
      "echo 'Installation de PostgreSQL...'",
      "sudo apt-get update",
      "sudo apt-get install -y postgresql postgresql-contrib",
      "sudo systemctl enable postgresql",
      "echo \"listen_addresses = '*'\" | sudo tee -a /etc/postgresql/*/main/postgresql.conf",
      "echo \"host all all 0.0.0.0/0 md5\" | sudo tee -a /etc/postgresql/*/main/pg_hba.conf"
    ]
  }
}
