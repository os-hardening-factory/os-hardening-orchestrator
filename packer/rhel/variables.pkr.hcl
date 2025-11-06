# Variables for RHEL Hardened Image (UBI Base)
variable "image_name" {
  type    = string
  default = "rhel-ubi-hardened"
}

variable "base_image" {
  type    = string
  default = "registry.access.redhat.com/ubi9/ubi"
}

variable "local_tag" {
  type    = string
  default = "latest"
}

variable "ansible_playbook" {
  type    = string
  default = "../../playbooks/rhel-hardening.yml"
}
