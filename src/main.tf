locals {
  enabled = module.this.enabled
}

resource "aws_vpc_endpoint_service" "this" {
  count = local.enabled ? 1 : 0

  acceptance_required        = var.vpc_endpoint_service_acceptance_required
  network_load_balancer_arns = length(var.vpc_endpoint_service_network_load_balancer_arns) > 0 ? var.vpc_endpoint_service_network_load_balancer_arns : null
  gateway_load_balancer_arns = length(var.vpc_endpoint_service_gateway_load_balancer_arns) > 0 ? var.vpc_endpoint_service_gateway_load_balancer_arns : null
  supported_ip_address_types = var.vpc_endpoint_service_supported_ip_address_types
  private_dns_name           = var.vpc_endpoint_service_private_dns_name

  tags = module.this.tags
}

resource "aws_vpc_endpoint_service_allowed_principal" "this" {
  for_each = local.enabled ? toset(var.vpc_endpoint_service_allowed_principals) : []

  vpc_endpoint_service_id = aws_vpc_endpoint_service.this[0].id
  principal_arn           = each.value
}

resource "aws_vpc_endpoint_connection_notification" "this" {
  count = local.enabled ? 1 : 0

  vpc_endpoint_service_id     = aws_vpc_endpoint_service.this[0].id
  connection_notification_arn = aws_sns_topic.endpoint_events[0].arn
  connection_events           = ["Accept", "Reject"]
}

resource "aws_sns_topic" "endpoint_events" {
  count = local.enabled ? 1 : 0

  name = "${module.this.id}-endpoint-events"
  tags = module.this.tags
}
