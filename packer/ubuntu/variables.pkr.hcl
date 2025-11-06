variable "base_image" {
  description = "Base Docker image"
  type        = string
  default     = "ubuntu:22.04"
}

variable "os_name" {
  description = "Operating System base name"
  type        = string
  default     = "ubuntu"
}

variable "os_version" {
  description = "Operating System version"
  type        = string
  default     = "22.04"
}

variable "cis_version" {
  description = "CIS Benchmark version"
  type        = string
  default     = "1.4"
}

variable "timestamp" {
  description = "Build timestamp in YYYYMMDD"
  default     = "${formatdate("YYYYMMDD", timestamp())}"
}

variable "image_name" {
  description = "Full enterprise image name"
  default     = "${var.os_name}-${var.os_version}-cis${var.cis_version}-hardening-${var.timestamp}"
}
