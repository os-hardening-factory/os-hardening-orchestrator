variable "os_name" {
  description = "Operating System base name"
  type        = string
  default     = "ubuntu"
}

variable "os_version" {
  description = "Operating System version (e.g., 22.04)"
  type        = string
  default     = "22.04"
}

variable "cis_version" {
  description = "CIS Benchmark version (e.g., 1.4)"
  type        = string
  default     = "1.4"
}

variable "timestamp" {
  description = "Build timestamp in YYYYMMDD format"
  default     = "${formatdate("YYYYMMDD", timestamp())}"
}

variable "image_name" {
  description = "Enterprise-compliant image name"
  default     = "${var.os_name}-${var.os_version}-cis${var.cis_version}-hardening-${var.timestamp}"
}
