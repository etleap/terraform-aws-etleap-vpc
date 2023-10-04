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
    main_app_ip              = local.app_main_private_ip
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

resource "aws_ssm_parameter" "app_hostname" {
  name        = local.app_hostname_config_name
  description = "Etleap ${var.deployment_id} - App Hostname"
  type        = "String"
  value       = local.context.app_hostname

  tags = {
    Deployment = var.deployment_id
  }
}

resource "aws_ssm_parameter" "app_private_ip" {
  name        = local.app_private_ip_config_name
  description = "Etleap ${var.deployment_id} - App Main Private IP"
  type        = "String"
  value       = local.app_main_private_ip

  tags = {
    Deployment = var.deployment_id
  }
}
