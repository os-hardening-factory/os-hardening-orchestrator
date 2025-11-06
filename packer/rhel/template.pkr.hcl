packer {
  required_plugins {
    docker = {
      source  = "github.com/hashicorp/docker"
      version = ">= 1.1.2"
    }
    ansible = {
      source  = "github.com/hashicorp/ansible"
      version = ">= 1.1.4"
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
    "ENV ANSIBLE_HOST_KEY_CHECKING=False",
    "ENV PACKER_BUILD_OS=rhel"
  ]
}

# ---------------------------------------------------------------------------
# Build definition
# ---------------------------------------------------------------------------
build {
  name    = var.image_name
  sources = ["source.docker.rhel"]

  # -------------------------------------------------------------------------
  # Step 1: Install Python and Ansible inside the container
  # -------------------------------------------------------------------------
provisioner "shell" {
  inline = [
    "set -euxo pipefail",
    "echo '📦 Detecting package manager...'",

    # Detect dnf or microdnf
    "if command -v dnf >/dev/null 2>&1; then PKG_MGR=dnf; elif command -v microdnf >/dev/null 2>&1; then PKG_MGR=microdnf; else echo '❌ No supported package manager found' && exit 1; fi",
    "echo '✅ Using package manager:' $PKG_MGR",

    # Update repositories
    "$PKG_MGR -y update --refresh || true",

    # Fix for curl-minimal conflicts
    "echo '🧹 Handling curl-minimal conflicts...'",
    "if $PKG_MGR list installed curl-minimal >/dev/null 2>&1; then $PKG_MGR -y remove curl-minimal || true; fi",

    # Install Python and dependencies safely
    "echo '📦 Installing Python, Pip, and utilities...'",
    "$PKG_MGR install -y --allowerasing python3 python3-pip git sudo which tzdata openssh-clients || $PKG_MGR install -y --nobest python3 python3-pip git sudo which tzdata openssh-clients",

    # Install Ansible via pip
    "echo '🐍 Installing Ansible via pip (bypassing subscription)...'",
    "pip3 install --no-cache-dir ansible==8.7.0",
    "ansible --version || echo '⚠️ Warning: Ansible version check failed, continuing...'",

    "echo '✅ System prepared for hardening execution.'"
  ]
}




  # -------------------------------------------------------------------------
  # Step 2: Copy Ansible playbook and roles into container
  # -------------------------------------------------------------------------
  provisioner "file" {
    source      = "${path.root}/ansible"
    destination = "/tmp/ansible"
  }

  # -------------------------------------------------------------------------
  # Step 3: Run CIS hardening playbook
  # -------------------------------------------------------------------------
  provisioner "ansible-local" {
    playbook_file = "packer/rhel/ansible/playbook.yml"
    playbook_dir  = "packer/rhel/ansible"
    role_paths    = ["packer/rhel/ansible/roles"]
    extra_arguments = ["-e", "ANSIBLE_HOST_KEY_CHECKING=False"]
  }

  # -------------------------------------------------------------------------
  # Step 4: Tag final image
  # -------------------------------------------------------------------------
  post-processor "docker-tag" {
    repository = var.image_name
    tags       = ["latest"]
  }
}
