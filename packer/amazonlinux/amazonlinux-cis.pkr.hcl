packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = ">= 1.1.0"
    }
    ansible = {
      source  = "github.com/hashicorp/ansible"
      version = ">= 1.0.0"
    }
  }
}

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
  type = string
}

locals {
  timestamp     = formatdate("YYYYMMDD-HHmm", timestamp())
  ami_name      = "amazonlinux-cis-${var.environment}-${local.timestamp}"
}

source "amazon-ebs" "amazonlinux_cis" {
  region                 = var.aws_region
  instance_type          = "t3.medium"
  ami_name               = local.ami_name
  associate_public_ip_address = true

  source_ami_filter {
    filters = {
      name                = "al2023-ami-2023.*-kernel-6.1-x86_64"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    owners      = ["137112412989"]
    most_recent = true
  }

  ssh_username = "ec2-user"

  tags = {
    Name        = local.ami_name
    Project     = var.project
    Environment = var.environment
    Compliance  = "CIS-Benchmark"
    ManagedBy   = "Packer"
  }
}

build {
  name    = "amazonlinux-cis-hardening"
  sources = ["source.amazon-ebs.amazonlinux_cis"]

  provisioner "ansible" {
    playbook_file = "./ansible/playbooks/site.yml"
  }

  post-processor "manifest" {
    output = "manifest.json"
  }

  post-processor "shell-local" {
    inline = [
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
