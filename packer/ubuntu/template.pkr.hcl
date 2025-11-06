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
source "docker" "ubuntu" {
  image  = var.base_image
  commit = true
  changes = [
    "LABEL os-hardening=true",
    "ENV DEBIAN_FRONTEND=noninteractive"
  ]
}

# ---------------------------------------------------------------------------
# Build definition
# ---------------------------------------------------------------------------
build {
  name    = var.image_name
  sources = ["source.docker.ubuntu"]

  # -------------------------------------------------------------------------
  # Step 1: Install dependencies and Ansible inside the container
  # -------------------------------------------------------------------------
  provisioner "shell" {
    inline = [
      "export DEBIAN_FRONTEND=noninteractive",
      "ln -fs /usr/share/zoneinfo/UTC /etc/localtime",
      "apt-get update -y",
      # Install Python and Ansible (critical for CIS playbook)
      "apt-get install -y tzdata python3 python3-apt git curl sudo ansible",
      # Set timezone non-interactively
      "dpkg-reconfigure --frontend noninteractive tzdata",
      # Validate Ansible installation
      "ansible --version || echo '✅ Ansible installed successfully'",
      # Cleanup
      "apt-get clean && rm -rf /var/lib/apt/lists/*"
    ]
  }

  # -------------------------------------------------------------------------
  # Step 2: Run CIS hardening Ansible playbook inside the image
  # -------------------------------------------------------------------------
  provisioner "ansible-local" {
    # ✅ Use absolute paths so it works in both CI and local
    playbook_file = "${path.root}/ansible/playbook.yml"
    playbook_dir  = "${path.root}/ansible"
    role_paths    = ["${path.root}/ansible/roles"]

    # Extra vars and host key handling
    extra_arguments = [
      "-e", "ANSIBLE_HOST_KEY_CHECKING=False",
      "--extra-vars", "ansible_python_interpreter=/usr/bin/python3"
    ]
  }

  # -------------------------------------------------------------------------
  # Step 3: Tag final image after successful hardening
  # -------------------------------------------------------------------------
  post-processor "docker-tag" {
    repository = var.image_name
    tags       = [var.local_tag]
  }
}
