# TODO See if it makes sense to use NAT gateway instead, avoids having to manage AMIs
resource "aws_instance" "nat" {
  count       = local.created_vpc_count
  tags        = merge({Name = "Etleap NAT ${var.deployment_id}", PatchGroup = "etleap-${var.deployment_id}"}, local.default_tags)
  volume_tags = merge({Name = "Etleap NAT", }, local.default_tags)

  ami                         = local.nat_ami
  instance_type               = var.nat_instance_type
  key_name                    = var.key_name
  iam_instance_profile        = aws_iam_instance_profile.nat[0].name
  vpc_security_group_ids      = [aws_security_group.nat[0].id]
  subnet_id                   = aws_subnet.b_public[0].id
  associate_public_ip_address = true
  source_dest_check           = false
  private_ip                  = var.nat_private_ip

  # The NAT AMI is based on the minimal AL2023 image, which doesn't include the
  # SSM agent. The agent is required for Patch Manager and SSM sessions.
  # user_data scripts only run on an instance's first boot, so changes to it
  # must replace the NAT rather than restart it in place.
  user_data                   = <<EOF
#!/bin/bash
dnf install -y amazon-ssm-agent
systemctl enable --now amazon-ssm-agent
EOF
  user_data_replace_on_change = true

  root_block_device {
    volume_type = "gp3"
    volume_size = 32
    encrypted   = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_instance_profile" "nat" {
  count = local.created_vpc_count

  tags = local.default_tags
  name = "Etleap-${var.deployment_id}-Nat"
  role = aws_iam_role.nat[0].name
}

resource "aws_iam_role" "nat" {
  count = local.created_vpc_count

  tags               = local.default_tags
  name               = "Etleap-${var.deployment_id}-Nat-Role"
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

resource "aws_security_group" "nat" {
  count       = local.created_vpc_count
  tags        = merge({Name = "Etleap NAT"}, local.default_tags)
  name        = "Etleap NAT"
  description = "Etleap NAT"
  vpc_id      = aws_vpc.etleap[0].id
}

resource "aws_security_group_rule" "nat-egress" {
  count             = local.created_vpc_count
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  security_group_id = aws_security_group.nat[0].id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "nat-ingress" {
  count             = local.created_vpc_count
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  security_group_id = aws_security_group.nat[0].id
  cidr_blocks       = [aws_subnet.a_private[0].cidr_block, aws_subnet.b_private[0].cidr_block, aws_subnet.c_private[0].cidr_block]
}

resource "aws_eip" "nat" {
  count    = local.created_vpc_count
  tags     = local.default_tags
  vpc      = true
}

resource "aws_eip_association" "nat" {
  count         = local.created_vpc_count
  instance_id   = aws_instance.nat[0].id
  allocation_id = aws_eip.nat[0].id
}
