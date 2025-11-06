packer {
  required_plugins { docker = { version = ">=1.0.8", source = "github.com/hashicorp/docker" } }
}

source "docker" "rhel" {
  image  = "rhel:latest"
  commit = true
}

build {
  name    = "rhel-hardened"
  sources = ["source.docker.rhel"]

  provisioner "ansible" {
    playbook_file = "./packer/rhel/ansible/playbook.yml"
  }

  post-processor "docker-tag" {
    repository = "661539128717.dkr.ecr.ap-south-1.amazonaws.com/hardened-rhel"
    tag        = "latest"
  }
}
