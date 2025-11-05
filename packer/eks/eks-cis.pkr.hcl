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

variable "aws_region" {}
variable "project" {}
variable "environment" {}
variable "os_name" {
  default = "eks"
}

locals {
  timestamp = regex_replace(timestamp(), "[-:T]", "")
  ami_name  = "eks-al2-cis-${var.environment}-${formatdate("YYYYMMDD-hhmm", timestamp())}"
}

source "amazon-ebs" "eks_cis" {
  region                  = var.aws_region
  instance_type           = "t3.medium"
  ami_name                = local.ami_name
  ami_description         = "CIS hardened Amazon Linux 2 AMI for EKS"
  associate_public_ip_address = true
  source_ami              = "ami-043332a3db16fb9a8"
  ssh_username            = "ec2-user"
  tags = {
    Name        = "eks-cis"
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Packer"
    Compliance  = "CIS-Benchmark"
  }
}

build {
  name    = "eks-cis-hardening"
  sources = ["source.amazon-ebs.eks_cis"]

  # Step 1: Bootstrap Python for Ansible
  provisioner "shell" {
    inline = [
      "sudo yum install -y python3 python3-pip",
      "sudo alternatives --set python3 /usr/bin/python3",
      "python3 --version"
    ]
  }

  # Step 2: Run Ansible for CIS hardening
  provisioner "ansible" {
    playbook_file = "${path.root}/ansible/playbooks/site.yml"
  }

  # Step 3: Save metadata manifest
  post-processor "manifest" {
    output = "${path.root}/manifest.json"
  }

  # Step 4: Upload metadata to S3
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
