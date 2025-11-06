packer {
  required_plugins {
    docker = { version = ">=1.0.8", source = "github.com/hashicorp/docker" }
    ansible = { version = ">=1.1.0", source = "github.com/hashicorp/ansible" }
  }
}

source "docker" "amazonlinux" {
  image  = "amazonlinux:latest"
  commit = true
}

build {
  name    = "amazonlinux-hardened"
  sources = ["source.docker.amazonlinux"]

  provisioner "shell" {
    inline = [
      "which dnf >/dev/null 2>&1 && dnf install -y python3 sudo || yum install -y python3 sudo",
      "ln -sf /usr/bin/python3 /usr/bin/python || true"
    ]
  }

  provisioner "ansible" {
    playbook_file    = "./packer/amazonlinux/ansible/playbook.yml"
    extra_arguments  = ["-e", "ansible_python_interpreter=/usr/bin/python3"]
  }

  post-processor "docker-tag" {
    repository = "661539128717.dkr.ecr.ap-south-1.amazonaws.com/hardened-amazonlinux"
    tags       = [var.local_tag]
  }
}

variable "local_tag" {
  type        = string
  description = "Tag for the hardened image version"
  default     = "latest"
}
