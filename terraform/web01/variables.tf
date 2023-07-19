variable "ipv4_address" {
  type        = string
  description = "IPv4 address of the machine"
}

variable "ipv6_address" {
  type        = string
  description = "IPv6 address of the machine"
}

variable "nixos_vars_file" {
  type        = string
  description = "File to write NixOS configuration variables to"
}

variable "nixos_flake_attr" {
  type        = string
  description = "NixOS configuration flake attribute"
}

variable "sops_secrets_file" {
  type        = string
  description = "Path to SOPS secrets file storing the secrets for ssh keys and cryptsetup keys"
}

variable "hostname" {
  type        = string
  description = "Zone name of the machine"
}

variable "dns_zone" {
  type        = string
  description = "DNS zone to add the machine to"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to add to the server"
}
