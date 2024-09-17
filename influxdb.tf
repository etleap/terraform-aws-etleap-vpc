resource "aws_timestreaminfluxdb_db_instance" "influx_db" {
  count                  = var.is_influx_db_in_secondary_region ? 0 : 1
  name                   = "Etleap-${var.deployment_id}-influx"
  username               = local.influx_db_username
  password               = local.influx_db_password
  db_instance_type       = "db.influx.medium"
  vpc_subnet_ids         = [local.subnet_a_private_id, local.subnet_b_private_id]
  vpc_security_group_ids = [aws_security_group.influxdb[0].id]
  allocated_storage      = 100
  organization           = "etleap"
  bucket                 = "raw_bucket"
  publicly_accessible    = false
  deployment_type        = var.ha_mode ? "WITH_MULTIAZ_STANDBY" : "SINGLE_AZ"
  tags                   = local.default_tags
  depends_on             = [ null_resource.are_influx_db_hostname_and_password_valid ]

  // Ignoring the name change as we had to change it due to the AWS-imposed limit is 40 characters, 
  // but some instances were already created with the old pattern and renaming would cause instances to be replaced.
  lifecycle {
    ignore_changes = [
      "name"
    ]
  }
}

module "influx_db_password" {
  count   = var.is_influx_db_in_secondary_region ? 0 : 1
  source  = "./modules/password"
  tags    = local.default_tags

  name   = "EtleapInfluxDBRootPassword${local.resource_name_suffix}"
  length = 20
}

resource "aws_secretsmanager_secret" "influx_db_api_token" {
  name = "EtleapInfluxDbApiToken${local.resource_name_suffix}"
}

resource "aws_s3_object" "influx_db_init_script" {
  bucket  = aws_s3_bucket.intermediate.id
  key     = "init-scripts/influx_db_init.sh"
  source  = "${path.module}/templates/influx-db-init.sh"
}

resource "aws_security_group" "influxdb" {
  count       = var.is_influx_db_in_secondary_region ? 0 : 1
  tags        = merge({ Name = "Etleap InfluxDB" }, local.default_tags)
  name        = "Etleap InfluxDB"
  description = "Etleap InfluxDB"
  vpc_id      = local.vpc_id
}

resource "aws_security_group_rule" "influxdb-ingress-8086-app" {
  count                    = var.is_influx_db_in_secondary_region ? 0 : 1
  type                     = "ingress"
  from_port                = 8086
  to_port                  = 8086
  protocol                 = "tcp"
  security_group_id        = aws_security_group.influxdb[0].id
  source_security_group_id = aws_security_group.app.id
}

moved {
  from = aws_security_group_rule.app-to-influxdb
  to   = aws_security_group_rule.influxdb-ingress-8086-app
}

resource "aws_security_group_rule" "influxdb-ingress-8086-emr" {
  count                    = var.is_influx_db_in_secondary_region ? 0 : 1
  type                     = "ingress"
  from_port                = 8086
  to_port                  = 8086
  protocol                 = "tcp"
  security_group_id        = aws_security_group.influxdb[0].id
  source_security_group_id = aws_security_group.emr.id
}

moved {
  from = aws_security_group_rule.emr-to-influxdb
  to   = aws_security_group_rule.influxdb-ingress-8086-emr
}