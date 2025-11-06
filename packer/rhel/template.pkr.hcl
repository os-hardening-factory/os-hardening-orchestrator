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


source "docker" "rhel" {
  image  = "rhel:latest"
  commit = true
}

build {
  name    = "rhel-hardened"
  sources = ["source.docker.rhel"]
  variables = ["packer/variables.pkr.hcl"]

  provisioner "ansible" {
    playbook_file = "./packer/rhel/ansible/playbook.yml"
  }

  post-processor "docker-tag" {
    repository = "661539128717.dkr.ecr.ap-south-1.amazonaws.com/hardened-rhel"
    tag        = "v1.0.0-cis1.4-20251106"
  }
}
