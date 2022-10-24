resource "aws_security_group" "elva-elb" {
  name        = "Etleap Elva ELB ${var.deployment_id}"
  description = "Rules for the Elva ELB"
  vpc_id      = var.vpc_id

  # For event traffic over HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # For event traffic over HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # For FluentD logs
  ingress {
    from_port   = 24224
    to_port     = 24224
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "elva-elb-allow-events" {
  type                     = "egress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.elva-elb.id
  source_security_group_id = aws_security_group.elva-node.id
}

resource "aws_security_group_rule" "elva-elb-allow-logs" {
  type                     = "egress"
  from_port                = 8889
  to_port                  = 8889
  protocol                 = "tcp"
  security_group_id        = aws_security_group.elva-elb.id
  source_security_group_id = aws_security_group.elva-node.id
}

resource "aws_security_group" "elva-node" {
  name        = "Etleap ${var.deployment_id} Elva Node"
  description = "Rules for the Elva nodes"
  vpc_id      = var.vpc_id

  # For event traffic
  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.elva-elb.id]
  }

  # For FluentD logs
  ingress {
    from_port       = 8889
    to_port         = 8889
    protocol        = "tcp"
    security_groups = [aws_security_group.elva-elb.id]
  }

  # Required to access apt and other install resources
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}