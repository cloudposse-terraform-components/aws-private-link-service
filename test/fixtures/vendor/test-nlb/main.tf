locals {
  enabled = module.this.enabled
  vpc     = module.vpc.outputs
}

module "vpc" {
  source  = "cloudposse/stack-config/yaml//modules/remote-state"
  version = "1.8.0"

  component = "vpc"

  context = module.this.context
}

resource "aws_lb" "this" {
  count = local.enabled ? 1 : 0

  name               = module.this.id
  internal           = var.internal
  load_balancer_type = var.load_balancer_type
  subnets            = local.vpc.private_subnet_ids

  enable_deletion_protection       = var.deletion_protection_enabled
  enable_cross_zone_load_balancing = var.cross_zone_load_balancing_enabled

  tags = module.this.tags
}

resource "aws_lb_target_group" "this" {
  count = local.enabled ? 1 : 0

  name     = "${module.this.id}-tg"
  port     = 80
  protocol = "TCP"
  vpc_id   = local.vpc.vpc_id

  health_check {
    enabled  = true
    protocol = "TCP"
    port     = 80
  }

  tags = module.this.tags
}

resource "aws_lb_listener" "this" {
  count = local.enabled ? 1 : 0

  load_balancer_arn = aws_lb.this[0].arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[0].arn
  }

  tags = module.this.tags
}
