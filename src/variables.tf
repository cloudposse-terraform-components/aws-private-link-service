variable "region" {
  type        = string
  description = "AWS Region"
}

###################################################
# VPC Endpoint Service Configuration
###################################################

variable "vpc_endpoint_service_acceptance_required" {
  type        = bool
  description = "Whether or not VPC endpoint connection requests to the service must be accepted by the service owner"
  default     = true
}

variable "vpc_endpoint_service_network_load_balancer_arns" {
  type        = list(string)
  description = "List of Network Load Balancer ARNs to associate with the VPC endpoint service"
  default     = []
}

variable "vpc_endpoint_service_gateway_load_balancer_arns" {
  type        = list(string)
  description = "List of Gateway Load Balancer ARNs to associate with the VPC endpoint service"
  default     = []
}

variable "vpc_endpoint_service_allowed_principals" {
  type        = list(string)
  description = "List of ARNs of principals allowed to discover the VPC endpoint service"
  default     = []
}

variable "vpc_endpoint_service_private_dns_name" {
  type        = string
  description = "Private DNS name for the VPC endpoint service"
  default     = null
}

variable "vpc_endpoint_service_supported_ip_address_types" {
  type        = list(string)
  description = "The supported IP address types. Valid values: ipv4, ipv6"
  default     = ["ipv4"]
}
