locals {
  ssm_parameter_prefix                = "/etleap/${var.deployment_id}"
  default_hostname                    = aws_lb.app.dns_name
  default_streaming_endpoint_hostname = var.enable_streaming_ingestion ? module.elva[0].elva_lb_public_address : ""
  elva_lb_internal_address_a          = var.enable_streaming_ingestion ? module.elva[0].elva_lb_private_address_a : ""
  elva_lb_internal_address_b          = var.enable_streaming_ingestion ? module.elva[0].elva_lb_private_address_b : ""
  context = {
    deployment_id                            = var.deployment_id
    db_password_arn                          = module.db_password.arn
    db_salesforce_password_arn               = module.db_salesforce_password.arn
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
    has_downgraded_dms_instace               = !var.disable_cdc_support && var.downgrade_cdc
    dms_downgraded_replication_instance_name = (!var.disable_cdc_support && var.downgrade_cdc) ? aws_dms_replication_instance.dms_downgraded[0].replication_instance_id : null
    dms_downgraded_replication_instance_arn  = (!var.disable_cdc_support && var.downgrade_cdc) ? aws_dms_replication_instance.dms_downgraded[0].replication_instance_arn : null
    account_id                               = data.aws_caller_identity.current.account_id
    db_address                               = aws_db_instance.db.address
    emr_cluster_config_name                  = "${local.ssm_parameter_prefix}/emr_cluster_dns"
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
  }
}

module "main_app" {
  count = var.app_available ? 1 : 0

  depends_on = [
    aws_route.prod_public,
    aws_emr_cluster.emr
  ]

  name              = "main"
  source            = "./modules/app/"
  instance_profile  = aws_iam_instance_profile.app.name
  network_interface = aws_network_interface.main_app.id

  ami                  = var.amis["app"]
  key_name             = var.key_name
  ssl_pem              = local.ssl_pem
  ssl_key              = local.ssl_key
  region               = var.region
  instance_type        = var.app_instance_type
  enable_public_access = var.enable_public_access

  deployment_id = var.deployment_id

  config = templatefile("${path.module}/templates/etleap-config.tmpl", {
    var                      = local.context,
    deployment_role          = "customervpc",
    main_app_ip              = "127.0.0.1",
    zookeeper_hosts_dns      = local.zookeeper_hosts_dns
    elva_lb_internal_address = local.elva_lb_internal_address_b
  })
  db_init = "/tmp/db-init.sh $(aws secretsmanager get-secret-value --secret-id ${module.db_root_password.arn} | jq -r .SecretString) $(aws secretsmanager get-secret-value --secret-id ${module.db_password.arn} | jq -r .SecretString) $(aws secretsmanager get-secret-value --secret-id ${module.db_salesforce_password.arn} | jq -r .SecretString) ${var.deployment_id} ${aws_db_instance.db.address}"

  tags = {
    Deployment = var.deployment_id
    AppRole = "main"
  }
}

module "secondary_app" {
  count = var.app_available && var.ha_mode ? 1 : 0

  depends_on = [
    aws_route.prod_public,
    aws_emr_cluster.emr
  ]

  name              = "secondary"
  source            = "./modules/app/"
  instance_profile  = aws_iam_instance_profile.app.name
  network_interface = aws_network_interface.secondary_app[0].id

  ami                  = var.amis["app"]
  key_name             = var.key_name
  ssl_pem              = local.ssl_pem
  ssl_key              = local.ssl_key
  region               = var.region
  instance_type        = var.app_instance_type
  enable_public_access = var.enable_public_access

  deployment_id = var.deployment_id

  config = templatefile("${path.module}/templates/etleap-config.tmpl", {
    var                      = local.context,
    deployment_role          = "customervpc_ha",
    main_app_ip              = element(tolist(aws_network_interface.main_app.private_ips[*]), 0),
    zookeeper_hosts_dns      = local.zookeeper_hosts_dns
    elva_lb_internal_address = local.elva_lb_internal_address_a
  })
  db_init = "/tmp/db-init.sh $(aws secretsmanager get-secret-value --secret-id ${module.db_root_password.arn} | jq -r .SecretString) $(aws secretsmanager get-secret-value --secret-id ${module.db_password.arn} | jq -r .SecretString) $(aws secretsmanager get-secret-value --secret-id ${module.db_salesforce_password.arn} | jq -r .SecretString) ${var.deployment_id} ${aws_db_instance.db.address}"

  tags = {
    Deployment = var.deployment_id
    AppRole = "secondary"
  }
}

resource "aws_network_interface" "main_app" {
  private_ips       = var.app_private_ip != null ? [var.app_private_ip] : null
  private_ips_count = 0
  subnet_id         = local.subnet_b_private_id
  security_groups   = [aws_security_group.app.id]
}

resource "aws_network_interface" "secondary_app" {
  count             = var.ha_mode ? 1 : 0
  private_ips       = var.secondary_app_private_ip != null ? [var.secondary_app_private_ip] : null
  private_ips_count = 0
  subnet_id         = local.subnet_a_private_id
  security_groups   = [aws_security_group.app.id]
}

resource "aws_acm_certificate" "etleap" {
  count            = var.acm_certificate_arn == null || var.streaming_endpoint_acm_certificate_arn == null ? 1 : 0
  private_key      = local.ssl_key
  certificate_body = local.ssl_pem

  tags = {
    Name = "Etleap Default"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_instance_profile" "app" {
  name = "EtleapApp${local.resource_name_suffix}"
  role = aws_iam_role.app.name
}

resource "aws_iam_role_policy_attachment" "ecr_readonly_access" {
  role       = aws_iam_role.app.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role" "app" {
  name               = "EtleapApp${local.resource_name_suffix}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

resource "aws_lb" "app" {
  name_prefix        = "etleap"
  internal           = !var.enable_public_access
  load_balancer_type = "application"
  subnets            = var.enable_public_access ? [local.subnet_a_public_id, local.subnet_b_public_id] : [local.subnet_a_private_id, local.subnet_b_private_id]
  security_groups    = [aws_security_group.app.id]
  idle_timeout       = 300

  tags = {
    Name = "Etleap LB ${var.deployment_id}"
  }
}

resource "aws_lb_listener" "app" {
  load_balancer_arn = aws_lb.app.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy      = "ELBSecurityPolicy-TLS13-1-3-2021-06"
  certificate_arn = var.acm_certificate_arn == null ? aws_acm_certificate.etleap[0].arn : var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_lb_target_group" "app" {
  name_prefix = "Etleap"
  port        = 443
  protocol    = "HTTPS"
  vpc_id      = local.vpc_id

  health_check {
    path     = "/__ver"
    protocol = "HTTPS"
    matcher  = "200,400"
  }
}

resource "aws_lb_target_group_attachment" "main_app" {
  count            = var.app_available ? 1 : 0
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = module.main_app[0].instance_id
  port             = 443
}

resource "aws_lb_target_group_attachment" "secondary_app" {
  count            = var.app_available && var.ha_mode ? 1 : 0
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = module.secondary_app[0].instance_id
  port             = 443
}
