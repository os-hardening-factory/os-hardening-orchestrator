# Variables for Ubuntu Hardened Image
variable "image_name" {
  type    = string
  default = "ubuntu-hardened"
}

variable "base_image" {
  type    = string
  default = "ubuntu:22.04"
}

variable "local_tag" {
  type    = string
  default = "latest"
}

variable "ansible_playbook" {
  type    = string
  default = "ansible/playbook.yml"
}
