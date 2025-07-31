resource "aws_db_instance" "db" {
  tags                         = local.default_tags
  identifier_prefix            = "etleap"
  allocated_storage            = 500
  storage_type                 = "gp2"
  engine                       = "mysql"
  engine_version               = "8.0.40"
  instance_class               = var.rds_instance_type
  db_name                      = "EtleapDB"
  username                     = "root"
  password                     = module.db_root_password.secret_string
  db_subnet_group_name         = aws_db_subnet_group.db.name
  parameter_group_name         = aws_db_parameter_group.mysql8-0-etleap.name
  vpc_security_group_ids       = [aws_security_group.db.id]
  backup_retention_period      = var.rds_backup_retention_period
  auto_minor_version_upgrade   = false
  storage_encrypted            = true
  skip_final_snapshot          = true
  copy_tags_to_snapshot        = true
  deletion_protection          = true
  performance_insights_enabled = true
  multi_az                     = var.ha_mode
  ca_cert_identifier           = "rds-ca-rsa4096-g1"

  allow_major_version_upgrade = var.rds_allow_major_version_upgrade
  apply_immediately           = var.rds_apply_immediately

  lifecycle {
    ignore_changes = [
      identifier_prefix,
      db_name
    ]
  }
}

resource "aws_db_subnet_group" "db" {
  tags       = local.default_tags
  name       = "etleap_db_${local.deployment_random}"
  subnet_ids = [local.subnet_a_private_id, local.subnet_b_private_id]
  
  lifecycle {
    ignore_changes = [
      name,
      description
    ]
  }
}

resource "aws_db_parameter_group" "mysql8-0-etleap" {
  tags        = local.default_tags
  name        = "etleap-mysql8-0-${local.deployment_random}"
  description = "MySQL 8.0 with Etleap modifications"
  family      = "mysql8.0"

  parameter {
    name         = "max_allowed_packet"
    value        = 546308096
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "character-set-client-handshake"
    value        = 0
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "collation_server"
    value        = "latin1_swedish_ci"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "character_set_server"
    value        = "latin1"
    apply_method = "immediate"
  }

  parameter {
    name         = "log_bin_trust_function_creators"
    value        = 1
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "binlog_format"
    value        = "ROW"
    apply_method = "immediate"
  }

  parameter {
    name         = "innodb_lock_wait_timeout"
    value        = 250
    apply_method = "immediate"
  }

  parameter {
    name         = "general_log"
    value        = "0"
    apply_method = "immediate"
  }

  parameter {
    name         = "long_query_time"
    value        = 0.05
    apply_method = "immediate"
  }

  parameter {
    name         = "slow_query_log"
    value        = 1
    apply_method = "immediate"
  }

  parameter {
    name         = "log_error_verbosity"
    value        = 2
    apply_method = "immediate"
  }

  parameter {
    name         = "slow_query_log"
    value        = 1
    apply_method = "immediate"
  }

  parameter {
    name         = "log_output"
    value        = "file"
    apply_method = "immediate"
  }

  parameter {
    name         = "binlog_checksum"
    value        = "none"
    apply_method = "immediate"
  }

  parameter {
    name         = "innodb_log_file_size"
    value        = 5463080960 # 10x max_allowed_packet
    apply_method = "pending-reboot"
  }
}

resource "aws_security_group" "db" {
  tags        = merge({ Name = "Etleap DB" }, local.default_tags)
  name        = "Etleap DB"
  description = "Etleap DB"
  vpc_id      = local.vpc_id
}

resource "aws_security_group_rule" "db-ingress-3306-app" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.db.id
  source_security_group_id = aws_security_group.app.id
}

moved {
  from = aws_security_group_rule.app-to-db
  to   = aws_security_group_rule.db-ingress-3306-app
}

resource "aws_ssm_parameter" "rds_hostname" {
  tags        = local.default_tags
  name        = local.rds_hostname_config_name
  description = "Etleap ${var.deployment_id} - RDS Hostname"
  type        = "String"
  value       = local.context.db_address
}

resource "aws_ssm_parameter" "rds_username" {
  tags        = local.default_tags
  name        = local.rds_username_config_name
  description = "Etleap ${var.deployment_id} - RDS Username"
  type        = "String"
  value       = local.context.db_username
}

resource "aws_ssm_parameter" "rds_password_arn" {
  tags        = local.default_tags
  name        = local.rds_password_arn_config_name
  description = "Etleap ${var.deployment_id} - RDS Password ARN"
  type        = "String"
  value       = local.context.db_password_arn
}

resource "aws_ssm_parameter" "rds_support_username" {
  tags        = local.default_tags
  name        = local.rds_support_username_config_name
  description = "Etleap ${var.deployment_id} - RDS Support Username"
  type        = "String"
  value       = local.context.db_support_username
}

resource "aws_ssm_parameter" "rds_support_password_arn" {
  tags        = local.default_tags
  name        = local.rds_support_password_arn_config_name
  description = "Etleap ${var.deployment_id} - RDS Support Password ARN"
  type        = "String"
  value       = local.context.db_support_password_arn
}

resource "aws_s3_object" "db_init_script" {
  bucket  = aws_s3_bucket.intermediate.id
  key     = "init-scripts/db_init.sh"
  source  = "${path.module}/templates/db-init.sh"
}
