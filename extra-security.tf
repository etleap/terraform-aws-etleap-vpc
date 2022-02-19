resource "aws_security_group_rule" "app-allow-extra-security-groups" {
  count = length(var.extra_security_groups)

  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.app.id
  source_security_group_id = var.extra_security_groups[count.index]
}

resource "aws_security_group_rule" "db-allow-extra-security-groups" {
  count = length(var.extra_security_groups)

  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.db.id
  source_security_group_id = var.extra_security_groups[count.index]
}

resource "aws_security_group_rule" "emr-allow-extra-security-groups" {
  count = length(var.extra_security_groups)

  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.emr.id
  source_security_group_id = var.extra_security_groups[count.index]
}
