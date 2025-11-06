packer {
  required_version = ">= 1.11.0"
  required_plugins {
    docker  = { version = ">= 1.1.2", source = "github.com/hashicorp/docker" }
    ansible = { version = ">= 1.1.4", source = "github.com/hashicorp/ansible" }
  }
}

source "docker" "ubuntu" {
  image  = var.base_image
  commit = true
}

build {
  name    = var.image_name
  sources = ["source.docker.ubuntu"]

  provisioner "shell" {
    inline = [
      "apt-get update -y",
      "apt-get install -y python3 python3-apt git curl openssh-client",
      "rm -rf /var/lib/apt/lists/*"
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
