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
  zookeeper1_private_ip      = element(tolist(aws_network_interface.zookeeper["1"].private_ips[*]), 0)

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
  post_install_script_command              = (var.post_install_script != null
    ? "aws s3 cp s3://${aws_s3_bucket.intermediate.bucket}/${aws_s3_object.customer_post_install_script[0].key} /tmp/post-install.sh && chmod 0755 /tmp/post-install.sh && /tmp/post-install.sh"
    : null)

  latest_app_amis = {
    af-south-1     = "ami-076f2ec206175a448"
    ap-east-1      = "ami-07ce822dd776185e8"
    ap-northeast-1 = "ami-0082fe279c753cef4"
    ap-northeast-2 = "ami-004edbfd4cd5c86b9"
    ap-south-1     = "ami-0104150ac67fd163e"
    ap-southeast-1 = "ami-0f6cd7c4e897dc4c1"
    ap-southeast-2 = "ami-0a461faa94a17cb86"
    ca-central-1   = "ami-0df83b68cb56797a4"
    eu-central-1   = "ami-050c409fd76e91d29"
    eu-north-1     = "ami-0e1378816aebb6d5f"
    eu-south-1     = "ami-05ab3e2a5dadef6df"
    eu-west-1      = "ami-00b37175a0d95d6ab"
    eu-west-2      = "ami-01037125fafa99d01"
    eu-west-3      = "ami-0b82bc806ea92a0d1"
    sa-east-1      = "ami-0578cf56aafeec7ac"
    us-east-1      = "ami-0e46dc1901a488282"
    us-east-2      = "ami-0e8bbefe6c5a24eff"
    us-west-1      = "ami-0e14063325f608c6d"
    us-west-2      = "ami-0c951270ac7e74796"
  }

  # TEMPORARY: Zookeeper stays on Ubuntu until it is migrated to AL2023
  # (VIK-7449). These are the Ubuntu AMIs that latest_app_amis held before the
  # AL2023 migration. Remove this map and zookeeper_ami once ZK is on AL2023.
  zookeeper_amis = {
    af-south-1     = "ami-00c3d948804bc9ac0"
    ap-east-1      = "ami-04900dbefe52f0292"
    ap-northeast-1 = "ami-03b4e26264e79e1b3"
    ap-northeast-2 = "ami-04d8c19ce85bf7bc4"
    ap-south-1     = "ami-05b4d805e813a75a3"
    ap-southeast-1 = "ami-0ed4ad5c849aae7fe"
    ap-southeast-2 = "ami-07950cf97c5b22ecd"
    ca-central-1   = "ami-015345ee32700d712"
    eu-central-1   = "ami-0f3c0b99dee438443"
    eu-north-1     = "ami-04769c93e87653487"
    eu-south-1     = "ami-04889e7fd638ca39b"
    eu-west-1      = "ami-01d7ca7d503247c4a"
    eu-west-2      = "ami-0eb8840519b09339f"
    eu-west-3      = "ami-07f529eb42ada0d59"
    sa-east-1      = "ami-0759355ae132089e2"
    us-east-1      = "ami-0e0a4106402da2799"
    us-east-2      = "ami-079378cd1a0c35a49"
    us-west-1      = "ami-0047b1dbf7c01e21f"
    us-west-2      = "ami-0f4ef8559c70234eb"
  }

  app_ami       = local.latest_app_amis[local.region]
  zookeeper_ami = local.zookeeper_amis[local.region]

  latest_nat_amis = {
    ap-northeast-1 = "ami-04105315e4af0eb33"
    ap-northeast-2 = "ami-04c9587692d8d61cd"
    ap-northeast-3 = "ami-0954fb6cc525faea9"
    ap-south-1     = "ami-0d987e1565167afbd"
    ap-southeast-1 = "ami-0578e77caf866f7de"
    ap-southeast-2 = "ami-00c53aab380797a3a"
    ca-central-1   = "ami-08d4fce19663e0e16"
    eu-central-1   = "ami-0c07db924117f765e"
    eu-north-1     = "ami-0ed78b85c80886c04"
    eu-west-1      = "ami-0afe5581a85a44d6f"
    eu-west-2      = "ami-0c8a44b5649708f33"
    eu-west-3      = "ami-0db94e21394fe467d"
    sa-east-1      = "ami-06f52948b037ced34"
    us-east-1      = "ami-0c8380aa4368b10f5"
    us-east-2      = "ami-0c6d4210ad2e9f3ef"
    us-west-1      = "ami-0b5c3673e0e8f729d"
    us-west-2      = "ami-0aa259f1cd40306d5"
  }

  nat_ami = local.latest_nat_amis[local.region]

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
    cognito_azure_identity_pool              = var.disable_cognito_identity_pool ? null : aws_cognito_identity_pool.etleap_azure_identity_pool[0].id
  }
}

data "aws_secretsmanager_secret_version" "influx_db_password" {
  count     = var.is_influx_db_in_secondary_region ? 1 : 0
  secret_id = var.influx_db_password_arn
}

