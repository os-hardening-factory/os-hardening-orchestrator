# ---------------------------------------------------------------------------
# Ubuntu Variables (Enterprise Naming Standard)
# ---------------------------------------------------------------------------

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
  description = "Build timestamp (override via CLI)"
  type        = string
  default     = "manual"
}

variable "image_name" {
  description = "Full enterprise image name"
  type        = string
  default     = "ubuntu-22.04-cis1.4-hardening-manual"
}

variable "cis_profile" {
  type    = string
  default = "cis1.0"
  description = "CIS hardening profile applied to this build."
}