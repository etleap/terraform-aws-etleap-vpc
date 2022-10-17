resource "aws_lb" "app" {
  name_prefix        = "etleap"
  internal           = !var.enable_public_access
  load_balancer_type = "application"
  subnets            = var.enable_public_access ? [local.subnet_a_public_id, local.subnet_b_public_id] : [local.subnet_a_private_id, local.subnet_b_private_id]
  security_groups    = [aws_security_group.app.id, module.elva[0].elva_elb_security_group.id]

  tags = {
    Name = "Etleap LB ${var.deployment_id}"
  }
}

resource "aws_lb_target_group" "app" {
  name_prefix = "Etleap"
  port        = 443
  protocol    = "HTTPS"
  vpc_id      = local.vpc_id

  health_check {
    path     = "/__ver"
    protocol = "HTTPS"
    matcher  = "200,400"
  }
}
