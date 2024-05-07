variable "name" {
}

variable "config" {
}

variable "instance_profile" {
}

variable "network_interface" {
}

variable "deployment_id" {
}

variable "db_init" {
}

variable "ami" {
}

variable "key_name" {
}

variable "ssl_pem" {
}

variable "ssl_key" {
}

variable "region" {
}

variable "instance_type" {
}

variable "enable_public_access" {
}

variable "app_role" {
}

variable "tags" {
  default = {}
}

resource "aws_instance" "app" {
  tags                 = merge({Name = "Etleap App ${var.deployment_id} ${var.name}", AppRole = var.app_role, }, var.tags)
  volume_tags          = merge({Name = "Etleap App", }, var.tags)
  instance_type        = var.instance_type
  ami                  = var.ami
  key_name             = var.key_name
  iam_instance_profile = var.instance_profile

  network_interface {
    network_interface_id = var.network_interface
    device_index         = 0
  }

  user_data_replace_on_change = true
  user_data = <<EOF
#cloud-config 
# -*- YAML -*-
apt_upgrade: true
locale: en_US.UTF-8
packages:
- mysql-client-core-5.7

write_files:
- path: /home/ubuntu/ssl_certificate/ssl.pem
  content: |
    ${indent(4, var.ssl_pem)}
  owner: ubuntu:ubuntu
- path: /home/ubuntu/ssl_certificate/ssl.key
  content: |
    ${indent(4, var.ssl_key)}
  owner: ubuntu:ubuntu
- path: /tmp/db-init.sh
  content: |
    ${indent(4, file("${path.module}/db-init.sh"))}
  owner: ubuntu:ubuntu
  permissions: "0755"
- path: /home/ubuntu/.etleap
  content: |
    ${indent(4, var.config)}
- path: /root/.aws/config
  content: |
    [default]
    region = ${var.region}
- path: /home/ubuntu/.aws/config
  content: |
    [default]
    region = ${var.region}

runcmd:
- "sed -i 's/\"dns\": \\[\".*\"\\]/\"dns\": [\"169.254.169.253\"]/g' /etc/docker/daemon.json"
- ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
- "service docker restart"
- ${var.db_init}
- yes | ssh-keygen -f /home/ubuntu/.ssh/id_rsa -N ''
- cat /home/ubuntu/.ssh/id_rsa.pub >> /home/ubuntu/.ssh/authorized_keys
- "apt-get update && apt-get -y upgrade"
- echo "server 169.254.169.123 prefer iburst" >> /etc/ntp.conf
- service ntp restart
- ntpq -pn

power_state:
  delay: "now"
  mode: reboot
  condition: True
  timeout: 30
EOF
}

output "instance_id" {
  value = aws_instance.app.id
}

output "instance_arn" {
  value = aws_instance.app.arn
}

output "instance_private_dns" {
  value = aws_instance.app.private_dns
}
