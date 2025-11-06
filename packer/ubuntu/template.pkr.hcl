packer {
  required_plugins { docker = { version = ">=1.0.8", source = "github.com/hashicorp/docker" } }
}

source "docker" "ubuntu" {
  image  = "ubuntu:latest"
  commit = true
}

build {
  name    = "ubuntu-hardened"
  sources = ["source.docker.ubuntu"]

  provisioner "ansible" {
    playbook_file = "./packer/ubuntu/ansible/playbook.yml"
  }

  post-processor "docker-tag" {
    repository = "661539128717.dkr.ecr.ap-south-1.amazonaws.com/hardened-ubuntu"
    tag        = "latest"
  }
}
