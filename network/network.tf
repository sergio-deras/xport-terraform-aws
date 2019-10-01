
# VPC
resource "aws_vpc" "vpc" {
  cidr_block = "${var.cidrs["vpc"]}"
  tags = {
    Name = "Lab VPC"
  }
}

#internet gateway

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = "${aws_vpc.vpc.id}"
  tags = {
    Name = "Lab IGW"
  }
}

# Route tables

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.internet_gateway.id}"
  }

  tags = {
    Name = "Public Route Table"
  }
}

resource "aws_default_route_table" "private" {
  default_route_table_id = "${aws_vpc.vpc.default_route_table_id}"

  tags = {
    Name = "Private Route Table"
  }
}

resource "aws_subnet" "web_subnet" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "${var.cidrs["web_subnet"]}"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_availability_zones[0]}"

  tags = {
    Name = "Web Subnet"
  }
}

resource "aws_subnet" "app_subnet" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "${var.cidrs["app_subnet"]}"
  map_public_ip_on_launch = false
  availability_zone       = "${var.aws_availability_zones[0]}"

  tags = {
    Name = "App Subnet"
  }
}

resource "aws_subnet" "rds1" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "${var.cidrs["rds1"]}"
  map_public_ip_on_launch = false
  availability_zone       = "${var.aws_availability_zones[0]}"

  tags = {
    Name = "RDS 1 Subnet"
  }
}

resource "aws_subnet" "rds2" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "${var.cidrs["rds2"]}"
  map_public_ip_on_launch = false
  availability_zone       = "${var.aws_availability_zones[1]}"

  tags = {
    Name = "RDS 2 Subnet"
  }
}

# Subnet Associations

resource "aws_route_table_association" "web_subnet_assoc" {
  subnet_id      = "${aws_subnet.web_subnet.id}"
  route_table_id = "${aws_route_table.public.id}"
}


resource "aws_route_table_association" "app_subnet_assoc" {
  subnet_id      = "${aws_subnet.app_subnet.id}"
  route_table_id = "${aws_default_route_table.private.id}"
}

resource "aws_db_subnet_group" "rds_subnetgroup" {
  name       = "rds_subnetgroup"
  subnet_ids = ["${aws_subnet.rds1.id}", "${aws_subnet.rds2.id}"]

  tags = {
    Name = "RDS Subnet Group"
  }
}

#Security groups

resource "aws_security_group" "web_sg" {
  name        = "sg_public"
  description = "Used for web instances, (load balancer access)"
  vpc_id      = "${aws_vpc.vpc.id}"

  #SSH
  ingress {
    from_port   = "${var.ssh_port}"
    to_port     = "${var.ssh_port}"
    protocol    = "tcp"
    cidr_blocks = ["${var.access_cidr}"]
  }

  #HTTP
  ingress {
    from_port   = "${var.http_port}"
    to_port     = "${var.http_port}"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Private Security Group

resource "aws_security_group" "app_sg" {
  name        = "sg_private"
  description = "Used for App instances"
  vpc_id      = "${aws_vpc.vpc.id}"

  # Access from other security groups

  #SSH
  ingress {
    from_port   = "${var.ssh_port}"
    to_port     = "${var.ssh_port}"
    protocol    = "tcp"
    cidr_blocks = ["${var.access_cidr}"]
  }

  #RDS
  egress {
    from_port   = "${var.db_port}"
    to_port     = "${var.db_port}"
    protocol    = "tcp"
    cidr_blocks =  ["0.0.0.0/0"]
  }


}

#RDS Security Group
resource "aws_security_group" "RDS" {
  name        = "sg_rds"
  description = "Used for DB instances"
  vpc_id      = "${aws_vpc.vpc.id}"

  # SQL access from public/private security group

  ingress {
    from_port       = "${var.db_port}"
    to_port         = "${var.db_port}"
    protocol        = "tcp"
    security_groups = ["${aws_security_group.app_sg.id}"]
  }
}