# ==============================================================
# Packer Template: CIS-Hardened Ubuntu 22.04 Base Image
# ==============================================================
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

# ==============================================================
# Variables
# ==============================================================
variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "base_ami" {
  type    = string
  default = "ami-0851b76e8b1bce90b" # Ubuntu 22.04 LTS (us-east-1)
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "project" {
  type    = string
  default = "os-hardening-factory"
}

# ==============================================================
# Source: AWS Builder
# ==============================================================
source "amazon-ebs" "ubuntu_cis" {
  region                  = var.aws_region
  instance_type           = var.instance_type
  source_ami              = var.base_ami
  ssh_username            = "ubuntu"
  ami_name                = "os-hardened-ubuntu-{{timestamp}}"
  associate_public_ip_address = true

  tags = {
    Name        = "os-hardened-ubuntu"
    Project     = var.project
    Compliance  = "CIS-Benchmark"
    ManagedBy   = "Packer"
  }
}

# ==============================================================
# Build Section
# ==============================================================
build {
  name    = "ubuntu-cis-hardening"
  sources = ["source.amazon-ebs.ubuntu_cis"]

  provisioner "ansible" {
    playbook_file = "ansible/playbook.yml"
  }

  post-processor "manifest" {
    output = "build-manifest.json"
  }
}
