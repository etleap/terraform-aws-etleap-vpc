resource "aws_security_group" "elva-elb" {
  tags        = var.tags
  name        = "Etleap Elva ELB ${var.deployment_id}"
  description = "Rules for the Elva ELB"
  vpc_id      = var.vpc_id
}

# For event traffic over HTTP
resource "aws_security_group_rule" "elva-elb-ingress-80" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.elva-elb.id
  cidr_blocks       = var.streaming_endpoint_access_cidr_blocks
}

resource "aws_security_group_rule" "elva-elb-ingress-80-app" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.elva-elb.id
  source_security_group_id = var.app_security_group_id
}

# For event traffic over HTTPS
resource "aws_security_group_rule" "elva-elb-ingress-443" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.elva-elb.id
  cidr_blocks       = var.streaming_endpoint_access_cidr_blocks
}

resource "aws_security_group_rule" "elva-elb-ingress-443-app" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.elva-elb.id
  source_security_group_id = var.app_security_group_id
}

# For FluentD logs
resource "aws_security_group_rule" "elva-elb-ingress-24224" {
  type              = "ingress"
  from_port         = 24224
  to_port           = 24224
  protocol          = "tcp"
  security_group_id = aws_security_group.elva-elb.id
  cidr_blocks       = var.streaming_endpoint_access_cidr_blocks
}

resource "aws_security_group_rule" "elva-elb-ingress-24224-app" {
  type                     = "ingress"
  from_port                = 24224
  to_port                  = 24224
  protocol                 = "tcp"
  security_group_id        = aws_security_group.elva-elb.id
  source_security_group_id = var.app_security_group_id
}

# Allow events
resource "aws_security_group_rule" "elva-elb-egress-3000-elva-node" {
  type                     = "egress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.elva-elb.id
  source_security_group_id = aws_security_group.elva-node.id
}

moved {
  from = aws_security_group_rule.elva-elb-allow-events
  to   = aws_security_group_rule.elva-elb-egress-3000-elva-node
}

# Allow logs
resource "aws_security_group_rule" "elva-elb-egress-8889-elva-node" {
  type                     = "egress"
  from_port                = 8889
  to_port                  = 8889
  protocol                 = "tcp"
  security_group_id        = aws_security_group.elva-elb.id
  source_security_group_id = aws_security_group.elva-node.id
}

moved {
  from = aws_security_group_rule.elva-elb-allow-logs
  to   = aws_security_group_rule.elva-elb-egress-8889-elva-node
}

resource "aws_security_group" "elva-node" {
  tags        = var.tags
  name        = "Etleap ${var.deployment_id} Elva Node"
  description = "Rules for the Elva nodes"
  vpc_id      = var.vpc_id
}

# For event traffic
resource "aws_security_group_rule" "elva-node-ingress-3000" {
  type                     = "ingress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.elva-node.id
  source_security_group_id = aws_security_group.elva-elb.id
}

# For FluentD logs
resource "aws_security_group_rule" "elva-node-ingress-8889" {
  type                     = "ingress"
  from_port                = 8889
  to_port                  = 8889
  protocol                 = "tcp"
  security_group_id        = aws_security_group.elva-node.id
  source_security_group_id = aws_security_group.elva-elb.id
}

# Required to access apt and other install resources
resource "aws_security_group_rule" "elva-node-egress-80" {
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.elva-node.id
  cidr_blocks       = ["0.0.0.0/0"]
}


# Required to access apt and other install resources
resource "aws_security_group_rule" "elva-node-egress-443" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.elva-node.id
  cidr_blocks       = ["0.0.0.0/0"]
}
