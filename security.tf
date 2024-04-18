resource "aws_security_group" "app" {
  name        = "Etleap App"
  description = "Etleap App"
  vpc_id      = local.vpc_id

  tags = {
    Name = "Etleap App"
  }
}

resource "aws_security_group" "db" {
  name        = "Etleap DB"
  description = "Etleap DB"
  vpc_id      = local.vpc_id

  tags = {
    Name = "Etleap DB"
  }
}

resource "aws_security_group" "emr" {
  name        = "Etleap EMR"
  description = "Etleap EMR Security Group"
  vpc_id      = local.vpc_id

  tags = {
    Name = "Etleap EMR"
  }
}

resource "aws_security_group" "emr-master-managed" {
  name                   = "EMR Master Managed"
  description            = "Rules managed by EMR for EMR master"
  vpc_id                 = local.vpc_id
  revoke_rules_on_delete = true

  tags = {
    Name = "Etleap EMR Master (managed by EMR)"
  }
}

resource "aws_security_group" "emr-slave-managed" {
  name                   = "EMR Slave Managed"
  description            = "Rules managed by EMR for EMR slave"
  vpc_id                 = local.vpc_id
  revoke_rules_on_delete = true

  tags = {
    Name = "Etleap EMR Slave (managed by EMR)"
  }
}

resource "aws_security_group" "emr-service-access-managed" {
  name                   = "EMR Service Access Managed"
  description            = "Rules managed by EMR for EMR service access"
  vpc_id                 = local.vpc_id
  revoke_rules_on_delete = true

  tags = {
    Name = "Etleap EMR Service Access (managed by EMR)"
  }
}

resource "aws_security_group_rule" "emr_master_service_access" {
  type                     = "ingress"
  from_port                = 9443
  to_port                  = 9443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.emr-service-access-managed.id
  source_security_group_id = aws_security_group.emr-master-managed.id
}

resource "aws_security_group_rule" "app-egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  security_group_id = aws_security_group.app.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "emr-egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  security_group_id = aws_security_group.emr.id
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

resource "aws_security_group_rule" "emr-to-app" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.app.id
  source_security_group_id = aws_security_group.emr.id
}

resource "aws_security_group_rule" "app-to-emr" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.emr.id
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

resource "aws_security_group_rule" "emr-to-emr" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.emr.id
  source_security_group_id = aws_security_group.emr.id
}

resource "aws_security_group_rule" "app-allow-ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.app.id
  cidr_blocks       = var.ssh_access_cidr_blocks
}

resource "aws_security_group_rule" "app-allow-web-ssl" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.app.id
  cidr_blocks       = var.app_access_cidr_blocks
}

resource "aws_security_group" "zookeeper" {
  name   = "Etleap zookeeper"
  vpc_id = local.vpc_id
  lifecycle {
    ignore_changes = [name, description, tags, tags_all] 
  }
  
  tags = {
    Name = "Etleap Zookeeper"
  }
}

resource "aws_security_group_rule" "zookeeper-allow-ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.zookeeper.id
  cidr_blocks       = var.ssh_access_cidr_blocks
}

# Connections to client port 2181 should be allowed from every running application that needs access to ZK cluster (app, monitor, job, emr, etc.)
resource "aws_security_group_rule" "emr-to-zookeeper" {
  type                     = "ingress"
  from_port                = 2181
  to_port                  = 2181
  protocol                 = "tcp"
  security_group_id        = aws_security_group.zookeeper.id
  source_security_group_id = aws_security_group.emr.id
}

resource "aws_security_group_rule" "app-to-zookeeper" {
  type                     = "ingress"
  from_port                = 2181
  to_port                  = 2181
  protocol                 = "tcp"
  security_group_id        = aws_security_group.zookeeper.id
  source_security_group_id = aws_security_group.app.id
}

# Connections to admin ports ZK 2888 & 3888 should be only allowed from other ZK nodes
resource "aws_security_group_rule" "zookeeper-in-2888" {
  type                     = "ingress"
  from_port                = 2888
  to_port                  = 2888
  protocol                 = "tcp"
  security_group_id        = aws_security_group.zookeeper.id
  source_security_group_id = aws_security_group.zookeeper.id
}

resource "aws_security_group_rule" "zookeeper-in-3888" {
  type                     = "ingress"
  from_port                = 3888
  to_port                  = 3888
  protocol                 = "tcp"
  security_group_id        = aws_security_group.zookeeper.id
  source_security_group_id = aws_security_group.zookeeper.id
}

resource "aws_security_group_rule" "zookeeper-out-all" {
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = -1
  security_group_id        = aws_security_group.zookeeper.id
  cidr_blocks              = ["0.0.0.0/0"]
}
