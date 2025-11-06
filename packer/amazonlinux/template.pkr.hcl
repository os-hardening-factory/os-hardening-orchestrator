packer {
  required_version = ">= 1.11.0"

  required_plugins {
    docker  = { version = ">= 1.1.2", source = "github.com/hashicorp/docker" }
    ansible = { version = ">= 1.1.4", source = "github.com/hashicorp/ansible" }
  }
}

# Use official Amazon Linux base image
source "docker" "al2023" {
  image  = var.base_image
  commit = true
  changes = [
    "LABEL os-hardening=true",
    "ENV LANG=en_US.UTF-8"
  ]
}

build {
  name    = var.image_name
  sources = ["source.docker.al2023"]

  # Install Ansible dependencies inside the image
  provisioner "shell" {
    inline = [
      "dnf install -y python3 git openssh-clients sudo",
      "dnf clean all"
    ]
  }

  # Run local Ansible playbook for CIS hardening
  provisioner "ansible-local" {
    playbook_file = var.ansible_playbook
  }

  # Tag and export hardened image
  post-processor "docker-tag" {
    repository = var.image_name
    tags       = [var.local_tag]
  }
}
