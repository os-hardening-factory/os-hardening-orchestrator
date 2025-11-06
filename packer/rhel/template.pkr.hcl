packer {
  required_version = ">= 1.11.0"

  required_plugins {
    docker  = { version = ">= 1.1.2", source = "github.com/hashicorp/docker" }
    ansible = { version = ">= 1.1.4", source = "github.com/hashicorp/ansible" }
  }
}

source "docker" "ubi9" {
  image  = var.base_image
  commit = true
  changes = [
    "LABEL os-hardening=true",
    "ENV LANG=en_US.UTF-8"
  ]
}

build {
  name    = var.image_name
  sources = ["source.docker.ubi9"]

  provisioner "shell" {
    inline = [
      "microdnf install -y python3 git openssh-clients sudo && microdnf clean all"
    ]
  }

  provisioner "ansible-local" {
    playbook_file = var.ansible_playbook
  }

  post-processor "docker-tag" {
    repository = var.image_name
    tags       = [var.local_tag]
  }
}
