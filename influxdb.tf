resource "aws_timestreaminfluxdb_db_instance" "influx_db" {
  count                  = var.is_influx_db_in_secondary_region ? 0 : 1
  name                   = "etleap-ingest-metrics${local.resource_name_suffix}"
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