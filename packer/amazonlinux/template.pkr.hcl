packer {
  required_plugins { docker = { version = ">=1.0.8", source = "github.com/hashicorp/docker" } }
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
    tag        = "latest"
  }
}
