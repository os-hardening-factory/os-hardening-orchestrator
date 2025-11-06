packer {
  required_version = ">= 1.11.0"

  required_plugins {
    docker = {
      # Pin EXACTLY to the latest available version in the public index
      version = "= 1.1.2"
      source  = "github.com/hashicorp/docker"
    }
    ansible = {
      version = "= 1.1.4"
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
    "ENV LANG=en_US.UTF-8",
    "ENV LC_ALL=en_US.UTF-8"
  ]
}

# ---------------------------------------------------------------------------
# Build definition
# ---------------------------------------------------------------------------
build {
  name    = var.image_name
  sources = ["source.docker.rhel"]

  # Install tools inside UBI9
  provisioner "shell" {
    inline = [
      "set -euo pipefail",
      # UBI9 uses microdnf reliably; fallback to dnf
      "command -v microdnf >/dev/null 2>&1 && microdnf update -y || true",
      "command -v microdnf >/dev/null 2>&1 && microdnf install -y python3 git openssh-clients sudo tzdata ansible || true",
      "command -v microdnf >/dev/null 2>&1 || (dnf -y update && dnf -y install python3 git openssh-clients sudo tzdata ansible || true)",
      "python3 --version || true",
      "ansible --version || true"
    ]
  }

  # Run CIS hardening
  provisioner "ansible-local" {
    playbook_file   = var.ansible_playbook
    playbook_dir    = "ansible"
    role_paths      = ["ansible/roles"]
    extra_arguments = ["-e", "ANSIBLE_HOST_KEY_CHECKING=False"]
  }

  # Tag final image
  post-processor "docker-tag" {
    repository = var.image_name
    tags       = ["latest"]
  }
}
