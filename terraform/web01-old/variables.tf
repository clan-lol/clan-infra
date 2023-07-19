variable "server_type" {
  type        = string
  default     = "cpx41"
  description = "Hetzner cloud server type"
}

variable "server_location" {
  type        = string
  default     = "hel1"
  description = "Hetzner cloud server location"
}

variable "nixos_vars_file" {
  type        = string
  description = "File to write NixOS configuration variables to"
}

variable "nixos_flake_attr" {
  type        = string
  description = "NixOS configuration flake attribute"
}

variable "domain" {
  type        = string
  description = "Domain name"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to add to the server"
}