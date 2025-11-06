packer {
  required_plugins {
    docker = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/docker"
    }
    ansible = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

# -----------------------------------------------------------------------------
# Source Docker image definition
# -----------------------------------------------------------------------------
source "docker" "amazonlinux" {
  image  = var.base_image
  commit = true
  changes = [
    "LABEL maintainer='CloudOps Team'",
    "LABEL cis_version='${var.cis_version}'",
    "LABEL os='amazonlinux2'"
  ]
}

# -----------------------------------------------------------------------------
# Build definition
# -----------------------------------------------------------------------------
build {
  name    = var.image_name
  sources = ["source.docker.amazonlinux"]

  # 1️⃣ Pre-install Python & Ansible inside container
  provisioner "shell" {
    inline = [
      "echo '🧩 Preparing container for Ansible provisioning...'",
      "if command -v dnf >/dev/null 2>&1; then sudo dnf install -y python3 python3-pip; else sudo yum install -y python3 python3-pip; fi",
      "pip3 install ansible",
      "ansible --version || echo '⚠️ Ansible installation failed!'",
      "echo '✅ System prepared for hardening execution.'"
    ]
  }

  # 2️⃣ Run the Ansible playbook from inside the container
  provisioner "ansible-local" {
    playbook_file     = "ansible/playbook.yml"
    playbook_dir      = "ansible"
    role_paths        = ["ansible/roles"]
    staging_directory = "/tmp/ansible"
    extra_arguments   = ["--verbose"]
  }

  # 3️⃣ Optional: Post-hardening cleanup (to keep image light)
  provisioner "shell" {
    inline = [
      "echo '🧹 Cleaning up build artifacts...'",
      "rm -rf /root/.cache /tmp/*",
      "yum clean all || true",
      "echo '✅ Cleanup complete. Image ready.'"
    ]
  }
}
