variable "region" {
  type        = string
  description = "AWS Region"
}

variable "internal" {
  type        = bool
  description = "Whether the load balancer is internal or internet-facing"
  default     = true
}

variable "load_balancer_type" {
  type        = string
  description = "The type of load balancer to create"
  default     = "network"
}

variable "deletion_protection_enabled" {
  type        = bool
  description = "Enable deletion protection on the load balancer"
  default     = false
}

variable "cross_zone_load_balancing_enabled" {
  type        = bool
  description = "Enable cross-zone load balancing"
  default     = true
}
