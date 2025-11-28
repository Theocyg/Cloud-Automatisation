# packer/web.pkr.hcl

# Configuration du Builder (l'usine à images)
source "googlecompute" "nginx-image" {
  project_id      = var.project_id
  source_image_family = "debian-11"
  zone            = var.zone
  ssh_username    = "packer"
  
  # Le nom final de l'image (ex: my-web-image-12345678)
  image_name      = "my-web-image-{{timestamp}}"
  
  # Connexion à GCP (Chemin relatif vers ton fichier JSON)
  account_file    = "../gcp-creds.json"
}

# Les étapes de fabrication
build {
  sources = ["source.googlecompute.nginx-image"]

  # Étape 1 : Installation de Nginx (Provisioning simple via Shell)
  # Plus tard, on remplacera ça par Ansible comme demandé dans le PDF
  provisioner "shell" {
    inline = [
      "echo 'Mise a jour du systeme...'",
      "sudo apt-get update",
      "echo 'Installation de Nginx...'",
      "sudo apt-get install -y nginx",
      "sudo systemctl enable nginx",
      "echo '<h1>Bienvenue sur mon serveur Web Packer !</h1>' | sudo tee /var/www/html/index.html"
    ]
  }
}
