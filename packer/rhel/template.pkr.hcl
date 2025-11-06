# ---------------------------------------------------------------------------
# RHEL 9 UBI – CIS 1.5 Hardening Template
# ---------------------------------------------------------------------------

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
# Docker Source – RHEL UBI Base
# ---------------------------------------------------------------------------
source "docker" "rhel" {
  image  = var.base_image
  commit = true
  changes = [
    "LABEL os-hardening=true",
    "ENV container docker",
    "ENV ANSIBLE_FORCE_COLOR=1"
  ]
}

# ---------------------------------------------------------------------------
# Build Definition
# ---------------------------------------------------------------------------
build {
  name    = var.image_name
  sources = ["source.docker.rhel"]

  # -------------------------------------------------------------------------
  # Step 1 – Install dependencies and Ansible inside container
  # -------------------------------------------------------------------------
  provisioner "shell" {
    inline = [
      "set -eux",
      "echo '📦 Installing system dependencies for CIS hardening...'",
      "microdnf install -y python3 python3-pip git sudo ansible-core",
      "pip3 install --no-cache-dir ansible==8.7.0",
      "ansible --version",
      "microdnf clean all",
      "echo '✅ Dependencies installed successfully.'"
    ]
  }

  # -------------------------------------------------------------------------
  # Step 2 – Run CIS hardening Ansible playbook
  # -------------------------------------------------------------------------
  provisioner "ansible-local" {
    playbook_file   = var.ansible_playbook
    playbook_dir    = "ansible"
    role_paths      = ["ansible/roles"]
    extra_arguments = ["-e", "ANSIBLE_HOST_KEY_CHECKING=False"]
  }

  # -------------------------------------------------------------------------
  # Step 3 – Cleanup temporary files and package cache
  # -------------------------------------------------------------------------
  provisioner "shell" {
    inline = [
      "set -eux",
      "echo '🧹 Cleaning up cache and temporary data...'",
      "rm -rf /tmp/* /var/cache/dnf /var/cache/yum",
      "echo '✅ Cleanup complete.'"
    ]
  }

  # -------------------------------------------------------------------------
  # Step 4 – Tag final image after hardening
  # -------------------------------------------------------------------------
  post-processor "docker-tag" {
    repository = var.image_name
    tags       = ["latest"]
  }
}
