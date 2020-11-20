variable "config" {
}

variable "instance_profile" {
}

variable "network_interface" {
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

variable "vpc_cidr_block_1" {
}

variable "vpc_cidr_block_2" {
}

variable "vpc_cidr_block_3" {
}

variable "app_private_ip" {
  default = null
}

resource "aws_instance" "app" {
  instance_type        = "t3.large"
  ami                  = var.ami
  key_name             = var.key_name
  iam_instance_profile = var.instance_profile

  network_interface {
    network_interface_id = var.network_interface
    device_index         = var.network_interface == null ? null : 0
  }

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

runcmd:
- "sed -i 's/\"dns\": \\[\".*\"\\]/\"dns\": [\"${var.vpc_cidr_block_1}.${var.vpc_cidr_block_2}.${var.vpc_cidr_block_3}.2\"]/g' /etc/docker/daemon.json"
- "service docker restart"
- ${var.db_init}
- yes | ssh-keygen -f /home/ubuntu/.ssh/id_rsa -N ''
- cat /home/ubuntu/.ssh/id_rsa.pub >> /home/ubuntu/.ssh/authorized_keys
- ". /home/ubuntu/.etleap && bash -c \"$(curl -sS -L https://deployment.etleap.com/deployment/v1/install.sh)\""
EOF

  tags = {
    Name = "Etleap App"
  }

  volume_tags = {
    Name = "Etleap App"
  }
}

resource "aws_eip" "app" {
  instance = aws_instance.app.id
  vpc      = true
}

output "instance_id" {
  value = aws_instance.app.id
}

output "app_public_ip_address" {
  value       = aws_eip.app.public_ip
  description = "App IP Address"
}
