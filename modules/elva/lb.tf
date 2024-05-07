resource "aws_lb" "elva" {
  # The name_prefix option has a max length of 6 characters, so its hard to differentiate this from the app ALB.
  # Probably not a good idea to include the deployment id here as they can be quite long and there is a 32 character limit for the name.
  tags               = merge({Name = "Etleap Elva LB ${var.deployment_id}"}, var.tags)
  name               = "etleap-streaming-endpoint-${var.deployment_random}"
  internal           = false
  load_balancer_type = "application"
  subnets            = [var.subnet_a_public_id, var.subnet_b_public_id]
  security_groups    = [aws_security_group.elva-elb.id]
  idle_timeout       = 300
}

# Get the private IP address assigned to the load balancer for each subnet
# Used by app to access Elva internally, even when IP addresses have been restricted
data "aws_network_interface" "lb_subnet_a_ni" {
  tags = var.tags

  filter {
    name   = "description"
    values = ["ELB ${aws_lb.elva.arn_suffix}"]
  }

  filter {
    name   = "subnet-id"
    values = [var.subnet_a_public_id]
  }
}

# Get the private IP address assigned to the load balancer for each subnet
# Used by app to access Elva internally, even when IP addresses have been restricted
data "aws_network_interface" "lb_subnet_b_ni" {
  filter {
    name   = "description"
    values = ["ELB ${aws_lb.elva.arn_suffix}"]
  }

  filter {
    name   = "subnet-id"
    values = [var.subnet_b_public_id]
  }
}

resource "aws_lb_listener" "elva_https" {
  tags              = var.tags
  load_balancer_arn = aws_lb.elva.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.elva.arn
  }
}

resource "aws_lb_listener" "elva_http" {
  tags              = var.tags
  load_balancer_arn = aws_lb.elva.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.elva.arn
  }
}

resource "aws_lb_target_group" "elva" {
  tags        = var.tags
  name        = "EtleapElva${var.deployment_id}"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = "/_ok"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 60
    timeout             = 5
  }
}