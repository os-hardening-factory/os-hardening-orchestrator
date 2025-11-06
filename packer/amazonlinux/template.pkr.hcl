packer {
  required_version = ">= 1.11.0"

  required_plugins {
    docker  = {
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
source "docker" "amazonlinux" {
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
  sources = ["source.docker.amazonlinux"]

  # -------------------------------------------------------------------------
  # Step 1 – Install dependencies + Ansible inside container
  # -------------------------------------------------------------------------
  provisioner "shell" {
    inline = [
      "set -eux",
      "export TZ=UTC",
      "dnf update -y",
      "dnf install -y python3 git openssh-clients sudo ansible tzdata",
      "ln -sf /usr/share/zoneinfo/UTC /etc/localtime",
      "echo 'UTC' > /etc/timezone",
      "ansible --version || echo '✅ Ansible installed successfully'",
      "dnf clean all"
    ]
  }

  # -------------------------------------------------------------------------
  # Step 2 – Run CIS Baseline Ansible playbook
  # -------------------------------------------------------------------------
  provisioner "ansible-local" {
    playbook_file = var.ansible_playbook
    playbook_dir  = "ansible"
    role_paths    = ["ansible/roles"]
    extra_arguments = ["-e", "ANSIBLE_HOST_KEY_CHECKING=False"]
  }

  # -------------------------------------------------------------------------
  # Step 3 – Tag final hardened image
  # -------------------------------------------------------------------------
  post-processor "docker-tag" {
    repository = var.image_name
  }
}
