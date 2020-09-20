resource "aws_vpc" "etleap" {
  cidr_block           = "${var.vpc_cidr_block_1}.${var.vpc_cidr_block_2}.${var.vpc_cidr_block_3}.0/22"
  enable_dns_hostnames = true

  tags = {
    Name = "Etleap VPC"
  }
}

resource "aws_internet_gateway" "etleap" {
  vpc_id = aws_vpc.etleap.id

  tags = {
    Name = "Etleap IG"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.etleap.id

  tags = {
    Name = "Etleap Private"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.etleap.id

  tags = {
    Name = "Etleap Public"
  }
}

resource "aws_route" "private" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  instance_id            = aws_instance.nat.id
}

resource "aws_route" "prod_public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.etleap.id
}

resource "aws_subnet" "a_private" {
  vpc_id            = aws_vpc.etleap.id
  cidr_block        = "${var.vpc_cidr_block_1}.${var.vpc_cidr_block_2}.${var.vpc_cidr_block_3 + 0}.0/24"
  availability_zone = "${var.region}a"

  tags = {
    Name = "Etleap A Private"
  }
}

resource "aws_subnet" "b_private" {
  vpc_id            = aws_vpc.etleap.id
  cidr_block        = "${var.vpc_cidr_block_1}.${var.vpc_cidr_block_2}.${var.vpc_cidr_block_3 + 1}.0/24"
  availability_zone = "${var.region}b"

  tags = {
    Name = "Etleap B Private"
  }
}

resource "aws_subnet" "a_public" {
  vpc_id            = aws_vpc.etleap.id
  cidr_block        = "${var.vpc_cidr_block_1}.${var.vpc_cidr_block_2}.${var.vpc_cidr_block_3 + 2}.0/24"
  availability_zone = "${var.region}a"

  tags = {
    Name = "Etleap A Public"
  }
}

resource "aws_subnet" "b_public" {
  vpc_id            = aws_vpc.etleap.id
  cidr_block        = "${var.vpc_cidr_block_1}.${var.vpc_cidr_block_2}.${var.vpc_cidr_block_3 + 3}.0/24"
  availability_zone = "${var.region}b"

  tags = {
    Name = "Etleap B Public"
  }
}

resource "aws_route_table_association" "a_private" {
  subnet_id      = aws_subnet.a_private.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "b_private" {
  subnet_id      = aws_subnet.b_private.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "a_public" {
  subnet_id      = aws_subnet.a_public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "b_public" {
  subnet_id      = aws_subnet.b_public.id
  route_table_id = aws_route_table.public.id
}
