# packer/app.pkr.hcl

# Note: Le type de source reste "googlecompute"
source "googlecompute" "app-image" {
  project_id      = var.project_id
  source_image_family = "debian-11"
  zone            = var.zone
  ssh_username    = "packer"
  image_name      = "my-app-image-{{timestamp}}"
  account_file    = "../gcp-creds.json"
}

build {
  sources = ["source.googlecompute.app-image"]

  provisioner "shell" {
    inline = [
      "echo 'Installation des dependances App...'",
      "sudo apt-get update",
      "sudo apt-get install -y python3 python3-pip git nodejs npm",
      "python3 --version",
      "node --version"
    ]
  }
}
