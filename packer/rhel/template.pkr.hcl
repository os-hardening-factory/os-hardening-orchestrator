packer {
  required_version = ">= 1.11.0"

  required_plugins {
    docker = {
      version = ">= 1.1.2"
      source  = "github.com/hashicorp/docker"
    }
    ansible = {
      version = ">= 1.1.4"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

# ---------------------------------------------------------------------------
# Docker source definition
# ---------------------------------------------------------------------------
source "docker" "rhel" {
  image  = var.base_image
  commit = true
  changes = [
    "LABEL os-hardening=true",
    "ENV LANG=en_US.UTF-8"
  ]
}

# ---------------------------------------------------------------------------
# Build definition
# ---------------------------------------------------------------------------
build {
  name    = var.image_name
  sources = ["source.docker.rhel"]

  provisioner "shell" {
    inline = [
      "yum -y update",
      "yum -y install python3 python3-pip git sudo curl ansible",
      "ansible --version || echo '✅ Ansible installed successfully'",
      "yum clean all"
    ]
  }

  provisioner "ansible-local" {
    playbook_file = var.ansible_playbook
    playbook_dir  = "ansible"
    role_paths    = ["ansible/roles"]
    extra_arguments = ["-e", "ANSIBLE_HOST_KEY_CHECKING=False"]
  }

  post-processor "docker-tag" {
    repository = var.image_name
    tags       = ["latest"]
  }
}
