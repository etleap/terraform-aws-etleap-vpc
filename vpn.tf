resource "aws_security_group_rule" "app-allow-vpn" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.app.id
  cidr_blocks              = [var.vpn_cidr_block]
}

resource "aws_security_group_rule" "db-allow-vpn" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.db.id
  cidr_blocks              = [var.vpn_cidr_block]
}

resource "aws_security_group_rule" "internal-allow-vpn" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.internal.id
  cidr_blocks              = [var.vpn_cidr_block]
}
