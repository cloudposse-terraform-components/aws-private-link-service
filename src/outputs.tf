# VPC Endpoint Service Outputs
output "vpc_endpoint_service_id" {
  description = "The ID of the VPC endpoint service"
  value       = try(aws_vpc_endpoint_service.this[0].id, null)
}

output "vpc_endpoint_service_arn" {
  description = "The ARN of the VPC endpoint service"
  value       = try(aws_vpc_endpoint_service.this[0].arn, null)
}

output "vpc_endpoint_service_name" {
  description = "The service name that consumers use to connect"
  value       = try(aws_vpc_endpoint_service.this[0].service_name, null)
}

output "vpc_endpoint_service_state" {
  description = "The state of the VPC endpoint service"
  value       = try(aws_vpc_endpoint_service.this[0].state, null)
}

output "endpoint_events_sns_topic_arn" {
  description = "The ARN of the SNS topic for endpoint connection events"
  value       = try(aws_sns_topic.endpoint_events[0].arn, null)
}
