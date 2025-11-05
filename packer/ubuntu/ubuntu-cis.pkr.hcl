packer {
  required_version = ">= 1.9.0"

  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = ">= 1.2.0"
    }
    ansible = {
      source  = "github.com/hashicorp/ansible"
      version = ">= 1.0.0"
    }
  }
}

# -------------------------------
# Variables
# -------------------------------
variable "aws_region" {
  type = string
}

variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "os_name" {
  type    = string
  default = "ubuntu"
}

# -------------------------------
# Source: Amazon EBS
# -------------------------------
source "amazon-ebs" "ubuntu_cis" {
  region                      = var.aws_region
  instance_type               = "t3.medium"
  ssh_username                = "ubuntu"
  ami_name                    = "ubuntu22-cis-${var.environment}-${formatdate("YYYYMMDD-hhmm", timestamp())}"
  ami_description             = "CIS Hardened Ubuntu 22.04 Base Image"
  associate_public_ip_address = true

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    owners      = ["099720109477"] # Canonical
    most_recent = true
  }

  tags = {
    Name        = "os-hardened-ubuntu"
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Packer"
    Compliance  = "CIS-Benchmark"
  }
}

# -------------------------------
# Build block
# -------------------------------
build {
  name    = "ubuntu-cis-hardening"
  sources = ["source.amazon-ebs.ubuntu_cis"]

  provisioner "ansible" {
    playbook_file = "${path.root}/ansible/playbooks/site.yml"
  }

  # ✅ Correct placement of manifest + shell-local
  post-processor "manifest" {
    output = "${path.root}/manifest.json"
  }

  post-processor "shell-local" {
    inline = [
      "echo '📦 Uploading metadata to S3...'",
      "bash ${path.root}/../shared/scripts/upload_metadata.sh"
    ]

    environment_vars = [
      "AWS_REGION=${var.aws_region}",
      "PROJECT=${var.project}",
      "ENVIRONMENT=${var.environment}",
      "OS_NAME=${var.os_name}",
      "MANIFEST_PATH=${path.root}/manifest.json"
    ]
  }
}

