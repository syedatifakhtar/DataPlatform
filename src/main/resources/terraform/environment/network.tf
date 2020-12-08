resource "aws_security_group" "allow_access" {
  name        = "allow_access_techradar_demo_${var.deployment_identifier}"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  depends_on = [aws_subnet.private_1,aws_subnet.private_2,aws_subnet.public_1,aws_subnet.public_2]

  lifecycle {
    ignore_changes = [
      ingress,
      egress,
    ]
  }

  tags = {
    name = "emr_test"
  }
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    name = "techradar_demo"
    deployment_identifier = var.deployment_identifier
    owner = var.owner
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "public_1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.0.0/22"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    name = "techradar_demo"
    deployment_identifier = var.deployment_identifier
    owner = var.owner
  }
}

resource "aws_subnet" "public_2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.4.0/22"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    name = "techradar_demo"
    deployment_identifier = var.deployment_identifier
    owner = var.owner
  }
}


resource "aws_subnet" "private_1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.8.0/22"
  availability_zone = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false

  tags = {
    name = "techradar_demo"
    deployment_identifier = var.deployment_identifier
    owner = var.owner
  }
}

resource "aws_subnet" "private_2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.12.0/22"
  availability_zone = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = false

  tags = {
    name = "techradar_demo"
    deployment_identifier = var.deployment_identifier
    owner = var.owner
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "r" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_main_route_table_association" "a" {
  vpc_id         = aws_vpc.main.id
  route_table_id = aws_route_table.r.id
}
