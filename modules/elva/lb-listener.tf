resource "aws_lb_listener" "elva_http" {
  load_balancer_arn = var.load_balancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type           = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "HTTP is not supported, please use HTTPS"
      status_code  = "505"
    }
  }
}

resource "aws_lb_listener_rule" "elva_https" {
  listener_arn = var.app_listener_arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.elva.arn
  }

  condition {
    path_pattern {
      values = ["/in/*"]
    }
  }
}

resource "aws_lb_listener_rule" "elva_http" {
  listener_arn = aws_lb_listener.elva_http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.elva.arn
  }

  condition {
    path_pattern {
      values = ["/in/*"]
    }
  }
}

resource "aws_lb_target_group" "elva" {
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