variable "image_name" {
  type    = string
  default = "amazonlinux-hardened"
}

variable "base_image" {
  type    = string
  default = "amazonlinux:2023"
}

variable "local_tag" {
  type    = string
  default = "latest"
}

variable "ansible_playbook" {
  type    = string
  default = "ansible/playbook.yml"
}
