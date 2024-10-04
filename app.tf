module "main_app" {
  count = var.app_available ? 1 : 0
  tags  = local.default_tags

  depends_on = [
    aws_route.prod_public,
    aws_emr_cluster.emr
  ]

  name              = "main"
  app_role          = "main" 
  source            = "./modules/app/"
  instance_profile  = aws_iam_instance_profile.app.name
  network_interface = aws_network_interface.main_app.id

  ami                  = var.amis["app"]
  key_name             = var.key_name
  ssl_pem              = local.ssl_pem
  ssl_key              = local.ssl_key
  region               = local.region
  instance_type        = var.app_instance_type
  enable_public_access = var.enable_public_access

  deployment_id = var.deployment_id

  config = templatefile("${path.module}/templates/etleap-config.tmpl", {
    var                      = local.context,
    deployment_role          = "customervpc",
    main_app_ip              = "127.0.0.1",
    zookeeper_hosts_dns      = local.zookeeper_hosts_dns
  })

  # Arguments: DB_ROOT_PASSWORD, ETLEAP_DB_PASSWORD, ETLEAP_RDS_HOSTNAME, ETLEAP_DB_SUPPORT_USERNAME, ETLEAP_DB_SUPPORT_PASSWORD
  db_init = "/tmp/db-init.sh $(aws secretsmanager get-secret-value --secret-id ${module.db_root_password.arn} | jq -r .SecretString) $(aws secretsmanager get-secret-value --secret-id ${module.db_password.arn} | jq -r .SecretString) ${aws_db_instance.db.address} etleap-support $(aws secretsmanager get-secret-value --secret-id ${module.db_support_password.arn} | jq -r .SecretString)"
  
  # Arguments: INFLUX_HOSTNAME, INFLUX_USERNAME, INFLUX_PASSWORD, SECRET_ARN
  influx_db_init = "aws s3 cp s3://${aws_s3_bucket.intermediate.bucket}/${aws_s3_object.influx_db_init_script.key} /tmp/influx-db-init.sh && chmod 0755 /tmp/influx-db-init.sh && /tmp/influx-db-init.sh ${local.context.influx_db_hostname} ${local.influx_db_username} ${local.influx_db_password} ${local.context.influx_db_api_token_arn}"
}

module "secondary_app" {
  count = var.app_available && var.ha_mode ? 1 : 0
  tags  = local.default_tags

  depends_on = [
    aws_route.prod_public,
    aws_emr_cluster.emr
  ]

  name              = "secondary"
  app_role          = "secondary"
  source            = "./modules/app/"
  instance_profile  = aws_iam_instance_profile.app.name
  network_interface = aws_network_interface.secondary_app[0].id

  ami                  = var.amis["app"]
  key_name             = var.key_name
  ssl_pem              = local.ssl_pem
  ssl_key              = local.ssl_key
  region               = local.region
  instance_type        = var.app_instance_type
  enable_public_access = var.enable_public_access

  deployment_id = var.deployment_id

  config = templatefile("${path.module}/templates/etleap-config.tmpl", {
    var                      = local.context,
    deployment_role          = "customervpc_ha",
    main_app_ip              = local.app_main_private_ip
    zookeeper_hosts_dns      = local.zookeeper_hosts_dns
  })

  # Arguments: DB_ROOT_PASSWORD, ETLEAP_DB_PASSWORD, ETLEAP_RDS_HOSTNAME, ETLEAP_DB_SUPPORT_USERNAME, ETLEAP_DB_SUPPORT_PASSWORD
  db_init = "/tmp/db-init.sh $(aws secretsmanager get-secret-value --secret-id ${module.db_root_password.arn} | jq -r .SecretString) $(aws secretsmanager get-secret-value --secret-id ${module.db_password.arn} | jq -r .SecretString) ${aws_db_instance.db.address} etleap-support $(aws secretsmanager get-secret-value --secret-id ${module.db_support_password.arn} | jq -r .SecretString)"

  # Arguments: INFLUX_HOSTNAME, INFLUX_USERNAME, INFLUX_PASSWORD, SECRET_ARN
  influx_db_init = "aws s3 cp s3://${aws_s3_bucket.intermediate.bucket}/${aws_s3_object.influx_db_init_script.key} /tmp/influx-db-init.sh && chmod 0755 /tmp/influx-db-init.sh && /tmp/influx-db-init.sh ${local.context.influx_db_hostname} ${local.influx_db_username} ${local.influx_db_password} ${local.context.influx_db_api_token_arn}"
}

resource "aws_network_interface" "main_app" {
  tags              = local.default_tags
  private_ips       = var.app_private_ip != null ? [var.app_private_ip] : null
  private_ips_count = 0
  subnet_id         = local.subnet_b_private_id
  security_groups   = [aws_security_group.app.id]
}

resource "aws_network_interface" "secondary_app" {
  count             = var.ha_mode ? 1 : 0
  tags              = local.default_tags
  private_ips       = var.secondary_app_private_ip != null ? [var.secondary_app_private_ip] : null
  private_ips_count = 0
  subnet_id         = local.subnet_a_private_id
  security_groups   = [aws_security_group.app.id]
}

resource "aws_acm_certificate" "etleap" {
  count            = var.acm_certificate_arn == null || var.streaming_endpoint_acm_certificate_arn == null ? 1 : 0
  tags             = merge({Name = "Etleap Default"}, local.default_tags)
  private_key      = local.ssl_key
  certificate_body = local.ssl_pem

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "app" {
  tags        = merge({ Name = "Etleap App" }, local.default_tags)
  name        = "Etleap App"
  description = "Etleap App"
  vpc_id      = local.vpc_id
}

resource "aws_security_group_rule" "app-ingress-app" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.app.id
  source_security_group_id = aws_security_group.app.id
}

moved {
  from = aws_security_group_rule.app-to-app
  to   = aws_security_group_rule.app-ingress-app
}

resource "aws_security_group_rule" "app-egress-app" {
  type                     = "egress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.app.id
  source_security_group_id = aws_security_group.app.id
}


resource "aws_security_group_rule" "app-egress-3306-db" {
  type                     = "egress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.app.id
  source_security_group_id = aws_security_group.db.id
}

resource "aws_security_group_rule" "app-egress-emr" {
  type                     = "egress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.app.id
  source_security_group_id = aws_security_group.emr.id
}

resource "aws_security_group_rule" "app-ingress-22" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.app.id
  cidr_blocks       = var.ssh_access_cidr_blocks
}

moved {
  from = aws_security_group_rule.app-allow-ssh
  to   = aws_security_group_rule.app-ingress-22
}

resource "aws_security_group_rule" "app-ingress-443" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.app.id
  cidr_blocks       = var.app_access_cidr_blocks
}

moved {
  from = aws_security_group_rule.app-allow-web-ssl
  to   = aws_security_group_rule.app-ingress-443
}

resource "aws_security_group_rule" "app-ingress-emr" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.app.id
  source_security_group_id = aws_security_group.emr.id
}

moved {
  from = aws_security_group_rule.emr-to-app
  to   = aws_security_group_rule.app-ingress-emr
}

resource "aws_security_group_rule" "app-ingress-dms" {
  count                    = var.disable_cdc_support ? 0 : 1
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.dms[0].id
  source_security_group_id = aws_security_group.app.id
}

moved {
  from = aws_security_group_rule.dms-to-app[0]
  to   = aws_security_group_rule.app-ingress-dms[0] 
}

resource "aws_security_group_rule" "app-egress-2181-zookeeper" {
  type                     = "egress"
  from_port                = 2181
  to_port                  = 2181
  protocol                 = "tcp"
  security_group_id        = aws_security_group.app.id
  source_security_group_id = aws_security_group.zookeeper.id
}

resource "aws_security_group_rule" "app-egress-8086-influxdb" {
  count                    = var.is_influx_db_in_secondary_region ? 0 : 1
  type                     = "egress"
  from_port                = 8086
  to_port                  = 8086
  protocol                 = "tcp"
  security_group_id        = aws_security_group.app.id
  source_security_group_id = aws_security_group.influxdb[0].id
}

# Required to access apt and other install resources, AWS APIs and deployment.etleap.com
resource "aws_security_group_rule" "app-egress-443" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.app.id
  cidr_blocks       = ["0.0.0.0/0"]
}

# Required to access apt and other install resources
resource "aws_security_group_rule" "app-egress-80" {
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.app.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "app-egress-external" {
  // the "for_each" argument must be a map, or set of strings; converting the list of maps 
  // to a single map with unique keys.
  // We can have multiple ports for the same cidr_block; to get around this, we use the list 
  // index as the key.
  for_each                 = { for idx, c in var.outbound_access_destinations : idx => c }
  type                     = "egress"
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.app.id
  cidr_blocks              = contains(keys(each.value), "cidr_block") ? [each.value.cidr_block] : null
  source_security_group_id = lookup(each.value, "target_security_group_id", null)
}

resource "aws_iam_instance_profile" "app" {
  tags = local.default_tags
  name = "EtleapApp${local.resource_name_suffix}"
  role = aws_iam_role.app.name
}

resource "aws_iam_role_policy_attachment" "ecr_readonly_access" {
  role       = aws_iam_role.app.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role" "app" {
  tags               = local.default_tags
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
  tags               = merge({Name = "Etleap LB ${var.deployment_id}"}, local.default_tags)
  name_prefix        = "etleap"
  internal           = !var.enable_public_access
  load_balancer_type = "application"
  subnets            = var.enable_public_access ? [local.subnet_a_public_id, local.subnet_b_public_id] : [local.subnet_a_private_id, local.subnet_b_private_id]
  security_groups    = [aws_security_group.app.id]
  idle_timeout       = 300
}

resource "aws_lb_listener" "app" {
  tags              = local.default_tags
  load_balancer_arn = aws_lb.app.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.acm_certificate_arn == null ? aws_acm_certificate.etleap[0].arn : var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_lb_target_group" "app" {
  tags        = local.default_tags
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

resource "aws_ssm_parameter" "app_hostname" {
  tags        = local.default_tags
  name        = local.app_hostname_config_name
  description = "Etleap ${var.deployment_id} - App Hostname"
  type        = "String"
  value       = local.context.app_hostname
}

resource "aws_ssm_parameter" "app_private_ip" {
  tags        = local.default_tags
  name        = local.app_private_ip_config_name
  description = "Etleap ${var.deployment_id} - App Main Private IP"
  type        = "String"
  value       = local.app_main_private_ip
}
