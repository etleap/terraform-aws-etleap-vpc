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

variable "influx_db_init" {
}

variable "post_install_script_command" {
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

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 32
    encrypted             = true
    delete_on_termination = true
  }

  ebs_block_device {
    device_name           = "/dev/xvdb"
    volume_type           = "gp3"
    volume_size           = 60
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_tokens                 = "optional"  # Allows IMDSv1
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 2
  }

  lifecycle {
    ignore_changes = [ebs_block_device]
  }

  user_data_replace_on_change = true
  user_data = <<EOF
#cloud-config 
# -*- YAML -*-
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
- resize2fs /dev/nvme1n1
- echo RESET grub-efi/install_devices | debconf-communicate grub-pc 
- apt-get update && DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y
- ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
- "service docker restart"
- ${var.db_init}
%{ if var.app_role == "main" ~}
- ${var.influx_db_init}
%{ endif ~}
- yes | ssh-keygen -f /home/ubuntu/.ssh/id_rsa -N ''
- cat /home/ubuntu/.ssh/id_rsa.pub >> /home/ubuntu/.ssh/authorized_keys
- echo "server 169.254.169.123 prefer iburst" >> /etc/ntp.conf
- service ntp restart
- ntpq -pn
%{ if var.post_install_script_command != null ~}
- ${var.post_install_script_command}
%{ endif ~}

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
