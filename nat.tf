# TODO See if it makes sense to use NAT gateway instead, avoids having to manage AMIs
resource "aws_instance" "nat" {
  count                       = local.created_vpc_count
  ami                         = data.aws_ami.nat.id
  instance_type               = var.nat_instance_type
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.nat[0].id]
  subnet_id                   = aws_subnet.b_public[0].id
  associate_public_ip_address = true
  source_dest_check           = false
  private_ip                  = var.nat_private_ip

  tags = {
    Name = "Etleap NAT ${var.deployment_id}"
  }

  volume_tags = {
    Name = "Etleap NAT"
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = [ ami ]
  }
}

# Automates the search for the latest NAT AMI
data "aws_ami" "nat" {
  most_recent      = true
  name_regex       = "^etleap-nat-gateway-*"
  owners           = [local.hosted_account_id]

  filter {
    name   = "name"
    values = ["etleap-nat-gateway-x86_64-*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_security_group" "nat" {
  count       = local.created_vpc_count
  name        = "Etleap NAT"
  description = "Etleap NAT"
  vpc_id      = aws_vpc.etleap[0].id

  tags = {
    Name = "Etleap NAT"
  }
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
  vpc      = true
}

resource "aws_eip_association" "nat" {
  count         = local.created_vpc_count
  instance_id   = aws_instance.nat[0].id
  allocation_id = aws_eip.nat[0].id
}
