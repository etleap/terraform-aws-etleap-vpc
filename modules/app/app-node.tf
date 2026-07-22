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
  tags                 = merge({Name = "Etleap App ${var.deployment_id} ${var.name}", AppRole = var.app_role, PatchGroup = "etleap-${var.deployment_id}", }, var.tags)
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
    http_tokens                 = "required"
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

write_files:
- path: /home/ec2-user/ssl_certificate/ssl.pem
  content: |
    ${indent(4, var.ssl_pem)}
  owner: ec2-user:ec2-user
- path: /home/ec2-user/ssl_certificate/ssl.key
  content: |
    ${indent(4, var.ssl_key)}
  owner: ec2-user:ec2-user
- path: /home/ec2-user/.etleap
  content: |
    ${indent(4, var.config)}
- path: /root/.aws/config
  content: |
    [default]
    region = ${var.region}
- path: /home/ec2-user/.aws/config
  content: |
    [default]
    region = ${var.region}

runcmd:
- resize2fs /dev/nvme1n1
- dnf upgrade -y
- "service docker restart"
- ${var.db_init}
%{ if var.app_role == "main" ~}
- ${var.influx_db_init}
%{ endif ~}
- yes | ssh-keygen -f /home/ec2-user/.ssh/id_rsa -N ''
- cat /home/ec2-user/.ssh/id_rsa.pub >> /home/ec2-user/.ssh/authorized_keys
- usermod -a -G ec2-user aws-kinesis-agent-user
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
