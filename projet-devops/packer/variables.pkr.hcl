# packer/variables.pkr.hcl

packer {
  required_plugins {
    googlecompute = {
      source  = "github.com/hashicorp/googlecompute"
      version = "~> 1"
    }
  }
}

# On définit les variables UNE SEULE FOIS
variable "project_id" {
  type    = string
  default = "cloud-automatisation"
}

variable "zone" {
  type    = string
  default = "europe-west1-b"
}
