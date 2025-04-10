locals {
  account_id                 = data.aws_caller_identity.current.account_id
  hosted_account_id          = "223848809711"
  ssm_parameter_prefix       = "/etleap/${var.deployment_id}"
  vpc_cidr_block             = "${var.vpc_cidr_block_1}.${var.vpc_cidr_block_2}.${var.vpc_cidr_block_3}.0/22"
  vpc_cidr_block_config_name = "${local.ssm_parameter_prefix}/vpc_cidr"
  default_hostname           = aws_lb.app.dns_name
  app_hostname_config_name   = "${local.ssm_parameter_prefix}/app_hostname"
  app_main_private_ip        = element(tolist(aws_network_interface.main_app.private_ips[*]), 0)
  app_private_ip_config_name = "${local.ssm_parameter_prefix}/app_private_ip"

  rds_hostname_config_name             = "${local.ssm_parameter_prefix}/rds_hostname"
  rds_username_config_name             = "${local.ssm_parameter_prefix}/rds_username"
  rds_password_arn_config_name         = "${local.ssm_parameter_prefix}/rds_password_arn"
  rds_support_username_config_name     = "${local.ssm_parameter_prefix}/rds_support_username"
  rds_support_password_arn_config_name = "${local.ssm_parameter_prefix}/rds_support_password_arn"

  default_streaming_endpoint_hostname = var.enable_streaming_ingestion ? module.elva[0].elva_lb_public_address : ""

  default_tags = merge({
    Deployment = var.deployment_id
  }, var.resource_tags)

  is_influx_db_in_secondary_region         = var.influx_db_hostname != null && var.influx_db_password_arn != null 
  influx_db_username                       = "root"
  influx_db_password                       = var.is_influx_db_in_secondary_region ? data.aws_secretsmanager_secret_version.influx_db_password[0].secret_string : module.influx_db_password[0].secret_string

  context = {
    deployment_id                            = var.deployment_id
    vpc_cidr_block                           = local.vpc_cidr_block
    vpc_subnet_a_id                          = local.subnet_a_private_id
    vpc_subnet_b_id                          = local.subnet_b_private_id
    vpc_subnet_c_id                          = local.subnet_c_private_id
    allow_support_role                       = var.allow_iam_support_role ? "true" : "false"
    db_username                              = "etleap-prod"
    db_password_arn                          = module.db_password.arn
    db_support_username                      = "etleap-support"
    db_support_password_arn                  = module.db_support_password.arn
    admin_password_arn                       = module.admin_password.arn
    deployment_secret_arn                    = module.deployment_secret.arn
    kms_key                                  = aws_kms_key.etleap_encryption_key.key_id
    first_name                               = var.first_name
    last_name                                = var.last_name
    email                                    = var.email
    setup_password                           = module.setup_password.secret_string
    s3_bucket                                = aws_s3_bucket.intermediate.id
    s3_role                                  = aws_iam_role.intermediate.arn
    has_dms_instance                         = !var.disable_cdc_support
    dms_role                                 = var.disable_cdc_support ? null : aws_iam_role.dms[0].arn
    dms_replication_instance_name            = var.disable_cdc_support ? null : lower(aws_dms_replication_instance.dms[0].replication_instance_id)
    dms_replication_instance_arn             = var.disable_cdc_support ? null : aws_dms_replication_instance.dms[0].replication_instance_arn    
    account_id                               = local.account_id
    db_address                               = aws_db_instance.db.address
    emr_cluster_config_name                  = "${local.ssm_parameter_prefix}/emr_cluster_dns"
    emr_cluster_id_parameter_name            = aws_ssm_parameter.emr_cluster_id.name
    app_hostname                             = var.app_hostname == null ? local.default_hostname : var.app_hostname
    github_username                          = var.github_username
    github_access_token_arn                  = var.github_access_token_arn
    connection_secrets                       = var.connection_secrets
    inbound_sns_arn                          = module.inbound_queue.sns_topic_arn
    inbound_sqs_arn                          = module.inbound_queue.sqs_queue_arn
    s3_kms_sse_key                           = var.s3_kms_encryption_key
    streaming_ingestion_enabled              = var.enable_streaming_ingestion
    streaming_endpoint_hostname              = var.streaming_endpoint_hostname == null ? local.default_streaming_endpoint_hostname : var.streaming_endpoint_hostname
    activity_log_table_name                  = aws_dynamodb_table.activity-log.id
    dms_proxy_bucket                         = var.dms_proxy_bucket
    influx_db_hostname                       = var.is_influx_db_in_secondary_region ? var.influx_db_hostname : aws_timestreaminfluxdb_db_instance.influx_db[0].endpoint
    influx_db_api_token_arn                  = aws_secretsmanager_secret.influx_db_api_token.arn
    iceberg_system_tables_db_name            = aws_glue_catalog_database.iceberg_system_tables_db.name
  }
}

data "aws_secretsmanager_secret_version" "influx_db_password" {
  count     = var.is_influx_db_in_secondary_region ? 1 : 0
  secret_id = var.influx_db_password_arn
}

