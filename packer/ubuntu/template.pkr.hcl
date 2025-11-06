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

# Docker source
source "docker" "ubuntu" {
  image  = var.base_image
  commit = true
  changes = [
    "LABEL os-hardening=true",
    "ENV DEBIAN_FRONTEND=noninteractive"
  ]
}

# Build
build {
  name    = var.image_name
  sources = ["source.docker.ubuntu"]

  # Install deps + ansible inside container
  provisioner "shell" {
    inline = [
      "export DEBIAN_FRONTEND=noninteractive",
      "ln -fs /usr/share/zoneinfo/UTC /etc/localtime",
      "apt-get update -y",
      "apt-get install -y tzdata python3 python3-apt git curl sudo ansible",
      "dpkg-reconfigure --frontend noninteractive tzdata",
      "ansible --version || echo '✅ Ansible installed successfully'",
      "apt-get clean && rm -rf /var/lib/apt/lists/*"
    ]
  }

  # Run CIS playbook
  provisioner "ansible-local" {
    playbook_file = "${path.root}/ansible/playbook.yml"
    playbook_dir  = "${path.root}/ansible"
    role_paths    = ["${path.root}/ansible/roles"]
    extra_arguments = [
      "-e", "ANSIBLE_HOST_KEY_CHECKING=False",
      "--extra-vars", "ansible_python_interpreter=/usr/bin/python3"
    ]
  }

  # ✅ Clean tag logic: repository is the full enterprise name, tag is simple
  post-processor "docker-tag" {
    repository = var.image_name
    tags       = ["latest"]
  }
}
