output "nlb_arn" {
  description = "The ARN of the Network Load Balancer"
  value       = try(aws_lb.this[0].arn, null)
}

output "nlb_id" {
  description = "The ID of the Network Load Balancer"
  value       = try(aws_lb.this[0].id, null)
}

output "nlb_dns_name" {
  description = "The DNS name of the Network Load Balancer"
  value       = try(aws_lb.this[0].dns_name, null)
}

output "nlb_zone_id" {
  description = "The canonical hosted zone ID of the Network Load Balancer"
  value       = try(aws_lb.this[0].zone_id, null)
}
