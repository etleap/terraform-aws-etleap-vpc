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

  private_ips_count = 0
  subnet_id         = element(local.subnet_ids, each.key)
  security_groups   = [aws_security_group.zookeeper.id]
}

resource "aws_instance" "zookeeper" {
  for_each = local.zookeeper_map

  instance_type = "t3.small"
  ami           = var.amis["app"]
  key_name      = var.key_name
  iam_instance_profile = aws_iam_instance_profile.zookeeper.name

  user_data_replace_on_change = true

  tags = {
    Name = "Etleap ${each.value} ${var.deployment_id}"
  }

  volume_tags = {
    Name = "Etleap ${each.value} ${var.deployment_id}"
  }

  network_interface {
    network_interface_id = aws_network_interface.zookeeper[each.key].id
    device_index         = 0
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = 50
    encrypted   = true
  }

  user_data = templatefile("${path.module}/templates/zookeeper-userdata.yml.tpl", {
    env = "vpc",
    region = var.region,
    hostname = each.value,
    datadog_active = 0,
    zookeeper_id = each.key,
    file_kinesis_install = file("${path.module}/templates/kinesis-install.sh"),
    file_zookeeper_install = file("${path.module}/templates/zookeeper-install.sh"),
    file_zookeeper_cron = file("${path.module}/templates/zookeeper-cron.sh"),
    file_zookeeper_monitor = file("${path.module}/templates/zookeeper-monitor.sh"),
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
