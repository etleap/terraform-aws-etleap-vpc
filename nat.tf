# TODO See if it makes sense to use NAT gateway instead, avoids having to manage AMIs
resource "aws_instance" "nat" {
  ami                         = var.amis["nat"]
  instance_type               = "m3.medium"
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.nat.id]
  subnet_id                   = aws_subnet.b_public.id
  associate_public_ip_address = true
  source_dest_check           = false

  tags = {
    Name = "Etleap NAT"
  }

  volume_tags = {
    Name = "Etleap NAT"
  }
}

resource "aws_security_group" "nat" {
  name        = "Etleap NAT"
  description = "Etleap NAT"
  vpc_id      = aws_vpc.etleap.id

  tags = {
    Name = "Etleap NAT"
  }
}

resource "aws_security_group_rule" "nat-egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  security_group_id = aws_security_group.nat.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "nat-ingress" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  security_group_id = aws_security_group.nat.id
  cidr_blocks       = [aws_subnet.b_private.cidr_block]
}
