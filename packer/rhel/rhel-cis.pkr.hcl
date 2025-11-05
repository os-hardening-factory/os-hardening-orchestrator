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
  type        = string
  description = "AWS region to build the AMI in"
}

variable "project" {
  type        = string
  description = "Project name"
}

variable "environment" {
  type        = string
  description = "Deployment environment (dev/stage/prod)"
}

variable "os_name" {
  type        = string
  description = "Operating system name (e.g., rhel, ubuntu)"
}

locals {
  timestamp    = regex_replace(timestamp(), "[-:T]", "")
  ami_name     = "rhel9-cis-${var.environment}-${formatdate("YYYYMMDD-HHmm", timestamp())}"
  manifest_dir = "${path.root}"
}

source "amazon-ebs" "rhel_cis" {
  region                  = var.aws_region
  instance_type           = "t3.small"
  ami_name                = local.ami_name
  associate_public_ip_address = true
  ssh_username            = "ec2-user"
  source_ami_filter {
    filters = {
      name                = "RHEL-9.*x86_64*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["309956199498"] # Red Hat official owner ID
  }

  tags = {
    Name        = "os-hardened-rhel"
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Packer"
    Compliance  = "CIS-Benchmark"
  }

  ami_description = "CIS-hardened RHEL 9 base image (${var.environment})"
}

build {
  name    = "rhel-cis-hardening"
  sources = ["source.amazon-ebs.rhel_cis"]

  provisioner "ansible" {
    playbook_file = "${path.root}/ansible/playbooks/site.yml"
  }

  post-processor "manifest" {
    output = "${local.manifest_dir}/manifest.json"
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
      "MANIFEST_PATH=${local.manifest_dir}/manifest.json"
    ]
  }
}
