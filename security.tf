resource "aws_security_group" "app" {
  name        = "Etleap App"
  description = "Etleap App"
  vpc_id      = aws_vpc.etleap.id

  tags = {
    Name = "Etleap App"
  }
}

resource "aws_security_group" "db" {
  name        = "Etleap DB"
  description = "Etleap DB"
  vpc_id      = aws_vpc.etleap.id

  tags = {
    Name = "Etleap DB"
  }
}

resource "aws_security_group" "internal" {
  name        = "Etleap Internal"
  description = "Etleap Internal Security Group"
  vpc_id      = aws_vpc.etleap.id

  tags = {
    Name = "Etleap Internal"
  }
}

resource "aws_security_group" "emr-master-managed" {
  name                   = "EMR Master Managed"
  description            = "Rules managed by EMR for EMR master"
  vpc_id                 = aws_vpc.etleap.id
  revoke_rules_on_delete = true

  tags = {
    Name = "Etleap EMR Master (managed by EMR)"
  }
}

resource "aws_security_group" "emr-slave-managed" {
  name                   = "EMR Slave Managed"
  description            = "Rules managed by EMR for EMR slave"
  vpc_id                 = aws_vpc.etleap.id
  revoke_rules_on_delete = true

  tags = {
    Name = "Etleap EMR Slave (managed by EMR)"
  }
}

resource "aws_security_group" "emr-service-access-managed" {
  name                   = "EMR Service Access Managed"
  description            = "Rules managed by EMR for EMR service access"
  vpc_id                 = aws_vpc.etleap.id
  revoke_rules_on_delete = true

  tags = {
    Name = "Etleap EMR Service Access (managed by EMR)"
  }
}

resource "aws_security_group_rule" "app-egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  security_group_id = aws_security_group.app.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "internal-egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  security_group_id = aws_security_group.internal.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "app-to-db" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.db.id
  source_security_group_id = aws_security_group.app.id
}

resource "aws_security_group_rule" "internal-to-app" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.app.id
  source_security_group_id = aws_security_group.internal.id
}

resource "aws_security_group_rule" "app-to-internal" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.internal.id
  source_security_group_id = aws_security_group.app.id
}

resource "aws_security_group_rule" "app-to-app" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.app.id
  source_security_group_id = aws_security_group.app.id
}

resource "aws_security_group_rule" "internal-to-internal" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.internal.id
  source_security_group_id = aws_security_group.internal.id
}

resource "aws_security_group_rule" "app-allow-ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.app.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "app-allow-web-ssl" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.app.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "app-allow-web-ysjes-rest-api" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  security_group_id = aws_security_group.app.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "app-allow-web-ysjes-healthchecks" {
  type              = "ingress"
  from_port         = 8081
  to_port           = 8081
  protocol          = "tcp"
  security_group_id = aws_security_group.app.id
  cidr_blocks       = ["0.0.0.0/0"]
}