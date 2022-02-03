resource "aws_db_instance" "db" {
  identifier_prefix            = "etleap"
  allocated_storage            = 500
  storage_type                 = "gp2"
  engine                       = "mysql"
  engine_version               = "8.0.23"
  instance_class               = "db.m5.large"
  name                         = "EtleapDB"
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

  allow_major_version_upgrade = var.rds_allow_major_version_upgrade
  apply_immediately           = var.rds_allow_major_version_upgrade

  lifecycle {
    ignore_changes = [
      identifier_prefix,
      name
    ]
  }
}

resource "aws_db_subnet_group" "db" {
  name       = "etleap_db_${random_id.deployment_random.hex}"
  subnet_ids = [local.subnet_a_private_id, local.subnet_b_private_id]
  
  lifecycle {
    ignore_changes = [
      name,
      description
    ]
  }
}

resource "aws_db_parameter_group" "mysql8-0-etleap" {
  name        = "etleap-mysql8-0-${random_id.deployment_random.hex}"
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

resource "aws_db_parameter_group" "mysql5-7-etleap" {
  name        = "etleap-mysql5-7-${random_id.deployment_random.hex}"
  description = "MySQL 5.7 with Etleap modifications"
  family      = "mysql5.7"

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

  parameter {
    name         = "innodb_log_file_size"
    value        = 5463080960 # 10x max_allowed_packet
    apply_method = "pending-reboot"
  }
}

resource "aws_db_parameter_group" "mysql5-6-etleap" {
  name        = "etleap-mysql5-6-${random_id.deployment_random.hex}"
  description = "MySQL 5.6 with Etleap modifications"
  family      = "mysql5.6"

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

  parameter {
    name         = "innodb_log_file_size"
    value        = 5463080960 # 10x max_allowed_packet
    apply_method = "pending-reboot"
  }
}
