locals {
  zookeeper_map = { 1 = "zookeeper1", 2 = "zookeeper2", 3 = "zookeeper3" }
  subnet_ids    = [local.subnet_a_private_id, local.subnet_b_private_id, local.subnet_c_private_id]
  zookeeper_base_hostname = "etleap.internal"

  # Generate map of [zk_id => zk_node_ip]
  zookeeper_hosts_dns = {
    for idx, net_interface in aws_network_interface.zookeeper :
      idx => element(tolist(net_interface.private_ips[*]), 0)
  }
}

resource "aws_network_interface" "zookeeper" {
  for_each = local.zookeeper_map
  tags     = local.default_tags

  private_ips_count = 0
  subnet_id         = element(local.subnet_ids, each.key)
  security_groups   = [aws_security_group.zookeeper.id]
}

resource "aws_instance" "zookeeper" {
  for_each    = local.zookeeper_map
  tags        = merge({Name = "Etleap ${each.value} ${var.deployment_id}"}, local.default_tags)
  volume_tags = merge({Name = "Etleap ${each.value} ${var.deployment_id}"}, local.default_tags)

  instance_type = "t3.small"
  ami           = local.app_ami
  key_name      = var.key_name
  iam_instance_profile = aws_iam_instance_profile.zookeeper.name

  user_data_replace_on_change = true

  lifecycle {
    ignore_changes = [ ebs_block_device ]
  }

  network_interface {
    network_interface_id = aws_network_interface.zookeeper[each.key].id
    device_index         = 0
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = 32
    encrypted   = true
  }

  ebs_block_device {
    device_name           = "/dev/xvdb"
    volume_type           = "gp3"
    volume_size           = 32
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_tokens                 = "required"
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 2
  }

  user_data = templatefile("${path.module}/templates/zookeeper-userdata.yml.tpl", {
    env = "vpc",
    region = local.region,
    hostname = each.value,
    datadog_active = 0,
    zookeeper_id = each.key,
    post_install_script_command = local.post_install_script_command
    file_kinesis_install = file("${path.module}/templates/kinesis-install.sh"),
    file_zookeeper_install = file("${path.module}/templates/zookeeper-install.sh"),
    file_zookeeper_cron = file("${path.module}/templates/zookeeper-cron.sh"),
    file_zookeeper_stat = file("${path.module}/templates/zookeeper-stat.sh"),
    file_zookeeper_monitor = file("${path.module}/templates/zookeeper-monitor.sh"),
    file_zookeeper_zxid_check = file("${path.module}/templates/zookeeper-zxid-check.sh"),
    file_docker_compose = templatefile("${path.module}/templates/zookeeper-docker-compose.yml.tpl", {
      zookeeper_id = each.key
      zookeeper_nodes = local.zookeeper_hosts_dns
      zookeeper_version = "3.7.1"
    }),
    config = templatefile("${path.module}/templates/zookeeper-config.tmpl", {
      deployment_id = var.deployment_id,
      deployment_secret_arn = module.deployment_secret.arn
    })
  })

}

resource "aws_security_group" "zookeeper" {
  tags   = merge({ Name = "Etleap Zookeeper" }, local.default_tags)
  name   = "Etleap zookeeper"
  vpc_id = local.vpc_id
  lifecycle {
    ignore_changes = [name, description, tags, tags_all]
  }
}

resource "aws_security_group_rule" "zookeeper-ingress-22" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.zookeeper.id
  cidr_blocks       = var.ssh_access_cidr_blocks
}

moved {
  from = aws_security_group_rule.zookeeper-allow-ssh
  to   = aws_security_group_rule.zookeeper-ingress-22
}

# Connections to client port 2181 should be allowed from every running application that needs access to ZK cluster (app, monitor, job, emr, etc.)
resource "aws_security_group_rule" "zookeeper-ingress-2181-emr" {
  type                     = "ingress"
  from_port                = 2181
  to_port                  = 2181
  protocol                 = "tcp"
  security_group_id        = aws_security_group.zookeeper.id
  source_security_group_id = aws_security_group.emr.id
}

moved {
  from = aws_security_group_rule.emr-to-zookeeper
  to   = aws_security_group_rule.zookeeper-ingress-2181-emr
}

resource "aws_security_group_rule" "zookeeper-ingress-2181-app" {
  type                     = "ingress"
  from_port                = 2181
  to_port                  = 2181
  protocol                 = "tcp"
  security_group_id        = aws_security_group.zookeeper.id
  source_security_group_id = aws_security_group.app.id
}

moved {
  from = aws_security_group_rule.app-to-zookeeper
  to   = aws_security_group_rule.zookeeper-ingress-2181-app
}

# Connections to admin ports ZK 2888 & 3888 should be only allowed from other ZK nodes
resource "aws_security_group_rule" "zookeeper-ingress-2888-zookeeper" {
  type                     = "ingress"
  from_port                = 2888
  to_port                  = 2888
  protocol                 = "tcp"
  security_group_id        = aws_security_group.zookeeper.id
  source_security_group_id = aws_security_group.zookeeper.id
}

moved {
  from = aws_security_group_rule.zookeeper-in-2888
  to   = aws_security_group_rule.zookeeper-ingress-2888-zookeeper
}

resource "aws_security_group_rule" "zookeeper-ingress-3888-zookeeper" {
  type                     = "ingress"
  from_port                = 3888
  to_port                  = 3888
  protocol                 = "tcp"
  security_group_id        = aws_security_group.zookeeper.id
  source_security_group_id = aws_security_group.zookeeper.id
}

moved {
  from = aws_security_group_rule.zookeeper-in-3888
  to   = aws_security_group_rule.zookeeper-ingress-3888-zookeeper
}

resource "aws_security_group_rule" "zookeeper-egress-2888-zookeeper" {
  type                     = "egress"
  from_port                = 2888
  to_port                  = 2888
  protocol                 = "tcp"
  security_group_id        = aws_security_group.zookeeper.id
  source_security_group_id = aws_security_group.zookeeper.id
}

moved {
  from = aws_security_group_rule.zookeeper-out-2888
  to   = aws_security_group_rule.zookeeper-egress-2888-zookeeper
}

resource "aws_security_group_rule" "zookeeper-egress-3888-zookeeper" {
  type                     = "egress"
  from_port                = 3888
  to_port                  = 3888
  protocol                 = "tcp"
  security_group_id        = aws_security_group.zookeeper.id
  source_security_group_id = aws_security_group.zookeeper.id
}

moved {
  from = aws_security_group_rule.zookeeper-out-3888
  to   = aws_security_group_rule.zookeeper-egress-3888-zookeeper
}

# Required to access apt and other install resources, AWS APIs and deployment.etleap.com
resource "aws_security_group_rule" "zookeeper-egress-443" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.zookeeper.id
  cidr_blocks       = ["0.0.0.0/0"]
}

# Required to access apt and other install resources
resource "aws_security_group_rule" "zookeeper-egress-80" {
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.zookeeper.id
  cidr_blocks       = ["0.0.0.0/0"]
}
