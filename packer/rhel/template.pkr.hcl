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
    "ENV LANG=en_US.UTF-8",
    "ENV TZ=UTC"
  ]
}

# ---------------------------------------------------------------------------
# Build definition
# ---------------------------------------------------------------------------
build {
  name    = var.image_name
  sources = ["source.docker.rhel"]

  # -------------------------------------------------------------------------
  # Step 1 – Install dependencies and Ansible via pip
  # -------------------------------------------------------------------------
  provisioner "shell" {
    inline = [
      "set -eux",
      "export TZ=UTC",
      "dnf update -y || true",
      "dnf install -y python3-pip python3 git openssh-clients sudo tzdata",
      "pip3 install --no-cache-dir ansible",
      "ln -sf /usr/share/zoneinfo/UTC /etc/localtime",
      "echo 'UTC' > /etc/timezone",
      "ansible --version || echo '✅ Ansible installed successfully'",
      "dnf clean all"
    ]
  }

  # -------------------------------------------------------------------------
  # Step 2 – Run CIS baseline Ansible playbook
  # -------------------------------------------------------------------------
  provisioner "ansible-local" {
    playbook_file   = var.ansible_playbook
    playbook_dir    = "ansible"
    role_paths      = ["ansible/roles"]
    extra_arguments = ["-e", "ANSIBLE_HOST_KEY_CHECKING=False"]
  }

  # -------------------------------------------------------------------------
  # Step 3 – Tag final hardened image
  # -------------------------------------------------------------------------
  post-processor "docker-tag" {
    repository = var.image_name
  }
}
