locals {
  default_hostname = var.ha_mode ? aws_lb.app[0].dns_name : "$(curl -sS http://169.254.169.254/latest/meta-data/public-ipv4)"
  context = {
    deployment_id                 = var.deployment_id
    db_password_arn               = module.db_password.arn
    db_salesforce_password_arn    = module.db_salesforce_password.arn
    admin_password_arn            = module.admin_password.arn
    deployment_secret_arn         = module.deployment_secret.arn
    kms_key                       = aws_kms_key.etleap_encryption_key.key_id
    first_name                    = var.first_name
    last_name                     = var.last_name
    email                         = var.email
    setup_password                = module.setup_password.secret_string
    s3_bucket                     = aws_s3_bucket.intermediate.id
    s3_role                       = aws_iam_role.intermediate.arn
    has_dms_instance              = !var.disable_cdc_support
    dms_role                      = var.disable_cdc_support ? null : aws_iam_role.dms[0].arn
    dms_replication_instance_arn  = var.disable_cdc_support ? null : aws_dms_replication_instance.dms[0].replication_instance_arn
    dms_replication_instance_name = var.disable_cdc_support ? null : lower(aws_dms_replication_instance.dms[0].replication_instance_id)
    account_id                    = data.aws_caller_identity.current.account_id
    db_address                    = aws_db_instance.db.address
    emr_cluster                   = aws_emr_cluster.emr.master_public_dns
    app_hostname                  = var.app_hostname == null ? local.default_hostname : var.app_hostname
    github_username               = var.github_username
    github_access_token_arn       = var.github_access_token_arn
    connection_secrets            = var.connection_secrets
    inbound_sns_arn               = module.inbound_queue.sns_topic_arn
    inbound_sqs_arn               = module.inbound_queue.sqs_queue_arn
    use_s3_kms_sse_key            = var.s3_kms_encryption_key != null
  }
}

module "main_app" {
  depends_on = [
    aws_route.prod_public,
    aws_emr_cluster.emr
  ]

  source            = "./modules/app/"
  instance_profile  = aws_iam_instance_profile.app.name
  network_interface = aws_network_interface.main_app.id

  ami                  = var.amis["app"]
  key_name             = var.key_name
  ssl_pem              = var.ssl_pem
  ssl_key              = var.ssl_key
  region               = var.region
  instance_type        = var.app_instance_type
  enable_public_access = var.enable_public_access

  config = templatefile("${path.module}/templates/etleap-config.tmpl", {
    var             = local.context,
    deployment_role = "customervpc",
    main_app_ip     = "127.0.0.1"
  })
  db_init = "/tmp/db-init.sh $(aws secretsmanager get-secret-value --secret-id ${module.db_root_password.arn} | jq -r .SecretString) $(aws secretsmanager get-secret-value --secret-id ${module.db_password.arn} | jq -r .SecretString) $(aws secretsmanager get-secret-value --secret-id ${module.db_salesforce_password.arn} | jq -r .SecretString) ${var.deployment_id} ${aws_db_instance.db.address}"
}

module "ha_app" {
  count = var.ha_mode ? 1 : 0
  depends_on = [
    aws_route.prod_public,
    aws_emr_cluster.emr
  ]

  source            = "./modules/app/"
  instance_profile  = aws_iam_instance_profile.app.name
  network_interface = aws_network_interface.ha_app[0].id

  ami                  = var.amis["app"]
  key_name             = var.key_name
  ssl_pem              = var.ssl_pem
  ssl_key              = var.ssl_key
  region               = var.region
  instance_type        = var.app_instance_type
  enable_public_access = var.enable_public_access

  config = templatefile("${path.module}/templates/etleap-config.tmpl", {
    var             = local.context,
    deployment_role = "customervpc_ha",
    main_app_ip     = element(tolist(aws_network_interface.main_app.private_ips[*]), 0)
  })
  db_init = "/tmp/db-init.sh $(aws secretsmanager get-secret-value --secret-id ${module.db_root_password.arn} | jq -r .SecretString) $(aws secretsmanager get-secret-value --secret-id ${module.db_password.arn} | jq -r .SecretString) $(aws secretsmanager get-secret-value --secret-id ${module.db_salesforce_password.arn} | jq -r .SecretString) ${var.deployment_id} ${aws_db_instance.db.address}"
}

resource "aws_network_interface" "main_app" {
  private_ips       = var.app_private_ip != null ? [var.app_private_ip] : null
  private_ips_count = 0
  subnet_id         = var.enable_public_access ? local.subnet_b_public_id : local.subnet_b_private_id
  security_groups   = [aws_security_group.app.id]
}

resource "aws_network_interface" "ha_app" {
  count           = var.ha_mode ? 1 : 0
  subnet_id       = var.enable_public_access ? local.subnet_a_public_id : local.subnet_b_private_id
  security_groups = [aws_security_group.app.id]
}

resource "aws_iam_server_certificate" "etleap" {
  count            = var.ha_mode ? 1 : 0
  name_prefix      = "Etleap_App_Cert_"
  private_key      = var.ssl_key
  certificate_body = var.ssl_pem

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb" "app" {
  count              = var.ha_mode ? 1 : 0
  name               = "etleap-app-alb"
  internal           = var.enable_public_access ? false : true
  load_balancer_type = "application"
  subnets            = var.enable_public_access ? [local.subnet_a_public_id, local.subnet_b_public_id] : [local.subnet_a_private_id, local.subnet_b_private_id]
  security_groups    = [aws_security_group.app.id]
}

resource "aws_lb_target_group" "app" {
  count    = var.ha_mode ? 1 : 0
  name     = "Etleap-App"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = local.vpc_id

  health_check {
    path     = "/__ver"
    protocol = "HTTPS"
    matcher  = "200,400"
  }
}

resource "aws_lb_listener" "app" {
  count             = var.ha_mode ? 1 : 0
  load_balancer_arn = aws_lb.app[0].arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_iam_server_certificate.etleap[0].arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app[0].arn
  }
}

resource "aws_lb_target_group_attachment" "main_app" {
  count            = var.ha_mode ? 1 : 0
  target_group_arn = aws_lb_target_group.app[0].arn
  target_id        = module.main_app.instance_id
  port             = 443
}

resource "aws_lb_target_group_attachment" "ha_app" {
  count            = var.ha_mode ? 1 : 0
  target_group_arn = aws_lb_target_group.app[0].arn
  target_id        = module.ha_app[0].instance_id
  port             = 443
}

resource "aws_iam_instance_profile" "app" {
  name = "EtleapApp${local.resource_name_suffix}"
  role = aws_iam_role.app.name
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
