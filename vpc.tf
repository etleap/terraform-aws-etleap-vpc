resource "aws_vpc" "etleap" {
  count                = local.created_vpc_count
  cidr_block           = local.vpc_cidr_block
  enable_dns_hostnames = true

  tags = {
    Name = "Etleap VPC ${var.deployment_id}"
  }
}

resource "aws_internet_gateway" "etleap" {
  count  = local.created_vpc_count
  vpc_id = aws_vpc.etleap[0].id

  tags = {
    Name = "Etleap IG"
  }
}

resource "aws_route_table" "private" {
  count  = local.created_vpc_count
  vpc_id = aws_vpc.etleap[0].id

  tags = {
    Name = "Etleap Private ${var.deployment_id}"
  }
}

resource "aws_route_table" "public" {
  count  = local.created_vpc_count
  vpc_id = aws_vpc.etleap[0].id

  tags = {
    Name = "Etleap Public ${var.deployment_id}"
  }
}

resource "aws_route" "private" {
  count                  = local.created_vpc_count
  route_table_id         = aws_route_table.private[0].id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_instance.nat[0].primary_network_interface_id
}

resource "aws_route" "prod_public" {
  count                  = local.created_vpc_count
  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.etleap[0].id
}

resource "aws_subnet" "a_private" {
  count             = local.created_vpc_count
  vpc_id            = aws_vpc.etleap[0].id
  cidr_block        = "${var.vpc_cidr_block_1}.${var.vpc_cidr_block_2}.${var.vpc_cidr_block_3 + 0}.0/24"
  availability_zone = "${var.region}a"

  tags = {
    Name = "Etleap A Private ${var.deployment_id}"
  }
}

resource "aws_subnet" "b_private" {
  count             = local.created_vpc_count
  vpc_id            = aws_vpc.etleap[0].id
  cidr_block        = "${var.vpc_cidr_block_1}.${var.vpc_cidr_block_2}.${var.vpc_cidr_block_3 + 1}.0/24"
  availability_zone = "${var.region}b"

  tags = {
    Name = "Etleap B Private ${var.deployment_id}"
  }
}

resource "aws_subnet" "c_private" {
  count             = local.created_vpc_count
  vpc_id            = aws_vpc.etleap[0].id
  cidr_block        = "${var.vpc_cidr_block_1}.${var.vpc_cidr_block_2}.${var.vpc_cidr_block_3 + 2}.0/24"
  availability_zone = "${var.region}c"

  tags = {
    Name = "Etleap C Private ${var.deployment_id}"
  }
}

resource "aws_subnet" "a_public" {
  count             = local.created_vpc_count
  vpc_id            = aws_vpc.etleap[0].id
  cidr_block        = "${var.vpc_cidr_block_1}.${var.vpc_cidr_block_2}.${var.vpc_cidr_block_3 + 3}.0/26"
  availability_zone = "${var.region}a"

  tags = {
    Name = "Etleap A Public ${var.deployment_id}"
  }
}

resource "aws_subnet" "b_public" {
  count             = local.created_vpc_count
  vpc_id            = aws_vpc.etleap[0].id
  cidr_block        = "${var.vpc_cidr_block_1}.${var.vpc_cidr_block_2}.${var.vpc_cidr_block_3 + 3}.64/26"
  availability_zone = "${var.region}b"

  tags = {
    Name = "Etleap B Public ${var.deployment_id}"
  }
}

resource "aws_subnet" "c_public" {
  count             = local.created_vpc_count
  vpc_id            = aws_vpc.etleap[0].id
  cidr_block        = "${var.vpc_cidr_block_1}.${var.vpc_cidr_block_2}.${var.vpc_cidr_block_3 + 3}.128/26"
  availability_zone = "${var.region}c"

  tags = {
    Name = "Etleap C Public ${var.deployment_id}"
  }
}

resource "aws_route_table_association" "a_private" {
  count          = local.created_vpc_count
  subnet_id      = aws_subnet.a_private[0].id
  route_table_id = aws_route_table.private[0].id
}

resource "aws_route_table_association" "b_private" {
  count          = local.created_vpc_count
  subnet_id      = aws_subnet.b_private[0].id
  route_table_id = aws_route_table.private[0].id
}

resource "aws_route_table_association" "c_private" {
  count          = local.created_vpc_count
  subnet_id      = aws_subnet.c_private[0].id
  route_table_id = aws_route_table.private[0].id
}

resource "aws_route_table_association" "a_public" {
  count          = local.created_vpc_count
  subnet_id      = aws_subnet.a_public[0].id
  route_table_id = aws_route_table.public[0].id
}

resource "aws_route_table_association" "b_public" {
  count          = local.created_vpc_count
  subnet_id      = aws_subnet.b_public[0].id
  route_table_id = aws_route_table.public[0].id
}

resource "aws_route_table_association" "c_public" {
  count          = local.created_vpc_count
  subnet_id      = aws_subnet.c_public[0].id
  route_table_id = aws_route_table.public[0].id
}

locals {
  vpc_id              = var.vpc_id == null ? aws_vpc.etleap[0].id : var.vpc_id
  subnet_a_private_id = var.vpc_id == null ? aws_subnet.a_private[0].id : var.private_subnets[0]
  subnet_b_private_id = var.vpc_id == null ? aws_subnet.b_private[0].id : var.private_subnets[1]
  subnet_c_private_id = var.vpc_id == null ? aws_subnet.c_private[0].id : var.private_subnets[2]
  subnet_a_public_id  = var.vpc_id == null ? aws_subnet.a_public[0].id : var.public_subnets[0]
  subnet_b_public_id  = var.vpc_id == null ? aws_subnet.b_public[0].id : var.public_subnets[1]
  subnet_c_public_id  = var.vpc_id == null ? aws_subnet.c_public[0].id : var.public_subnets[2]
  created_vpc_count   = var.vpc_id == null ? 1 : 0
}

resource "aws_ssm_parameter" "vpc_cidr" {
  name        = local.vpc_cidr_block_config_name
  description = "Etleap ${var.deployment_id} - VPC CIDR"
  type        = "String"
  value       = local.vpc_cidr_block

  tags = {
    Deployment = var.deployment_id
  }
}
