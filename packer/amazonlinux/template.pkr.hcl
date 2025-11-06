packer {
  required_plugins {
    docker = {
      version = ">=1.0.8"
      source  = "github.com/hashicorp/docker"
    }
    ansible = {
      version = ">=1.1.0"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

variable "local_tag" {
  type = string
  default = "amazonlinux-hardened:latest"
}

source "docker" "amazonlinux" {
  image  = "amazonlinux:latest"
  commit = true
}

build {
  name    = "amazonlinux-hardened"
  sources = ["source.docker.amazonlinux"]

  provisioner "ansible" {
    playbook_file = "./packer/amazonlinux/ansible/playbook.yml"
  }

  post-processor "docker-tag" {
    repository = "661539128717.dkr.ecr.ap-south-1.amazonaws.com/hardened-amazonlinux"
    tag        = "v1.0.0-cis1.4-20251106"
  }
}
