resource "aws_db_instance" "db" {
  identifier_prefix            = "etleap"
  allocated_storage            = 500
  storage_type                 = "gp2"
  engine                       = "mysql"
  engine_version               = "5.6.41"
  instance_class               = "db.m5.large"
  name                         = "EtleapDB"
  username                     = "root"
  password                     = data.aws_secretsmanager_secret_version.db_root_password.secret_string
  db_subnet_group_name         = aws_db_subnet_group.db.name
  parameter_group_name         = aws_db_parameter_group.mysql5-6-etleap.name
  vpc_security_group_ids       = [aws_security_group.db.id]
  backup_retention_period      = 7
  auto_minor_version_upgrade   = false
  storage_encrypted            = true
  skip_final_snapshot          = true
  copy_tags_to_snapshot        = true
  deletion_protection          = true
  performance_insights_enabled = true
}

resource "aws_db_subnet_group" "db" {
  name       = "etleap_db_${random_id.deployment_random.hex}"
  subnet_ids = [aws_subnet.a_private.id, aws_subnet.b_private.id]
}

resource "aws_db_parameter_group" "mysql5-6-etleap" {
  name        = "etleap-mysql5-6-${random_id.deployment_random.hex}"
  description = "MySQL 5.6 with Etleap modifications"
  family      = "mysql5.6"

  parameter {
    name         = "max_allowed_packet"
    value        = 16777216
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
    apply_method = "immediate"
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
    name         = "log_warnings"
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
}
