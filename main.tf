provider "aws" {
  region = "${var.aws_region}"
}

data "aws_availability_zones" "available" {}

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
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"

  tags = {
    Name = "Web Subnet"
  }
}

resource "aws_subnet" "app_subnet" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "${var.cidrs["app_subnet"]}"
  map_public_ip_on_launch = false
  availability_zone       = "${data.aws_availability_zones.available.names[1]}"

  tags = {
    Name = "App Subnet"
  }
}

resource "aws_subnet" "rds1" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "${var.cidrs["rds1"]}"
  map_public_ip_on_launch = false
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"

  tags = {
    Name = "RDS 1 Subnet"
  }
}

resource "aws_subnet" "rds2" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "${var.cidrs["rds2"]}"
  map_public_ip_on_launch = false
  availability_zone       = "${data.aws_availability_zones.available.names[1]}"

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
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_db_subnet_group" "rds_subnetgroup" {
  name       = "rds_subnetgroup"
  subnet_ids = ["${aws_subnet.rds1.id}", "${aws_subnet.rds2.id}"]

  tags = {
    Name = "RDS SG"
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
    cidr_blocks = ["${var.localip}"]
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
    cidr_blocks = ["${var.localip}"]
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

#RDS
/*
resource "aws_db_instance" "db" {
  allocated_storage      = 10
  engine                 = "mysql"
  port                   = "${var.db_port}"
  instance_class         = "${var.db_instance_class}"
  name                   = "${var.dbname}"
  username               = "${var.dbuser}"
  password               = "${var.dbpassword}"
  db_subnet_group_name   = "${aws_db_subnet_group.rds_subnetgroup.name}"
  vpc_security_group_ids = ["${aws_security_group.RDS.id}"]
  skip_final_snapshot    = true
}
*/
# key pair

resource "aws_key_pair" "auth" {
  key_name   = "${var.key_name}"
  public_key = "${file(var.public_key_path)}"
}

# server

resource "aws_instance" "dev" {
  instance_type = "${var.dev_instance_type}"
  ami           = "${var.dev_ami}"

  tags = {
    Name = "wordpress-instance"
  }

  key_name               = "${aws_key_pair.auth.id}"
  vpc_security_group_ids = ["${aws_security_group.web_sg.id}"]
  subnet_id              = "${aws_subnet.web_subnet.id}"
}


# ALB
resource "aws_alb" "web_alb" {
  name            = "web-alb"
  security_groups = ["${aws_security_group.web_sg.id}"]
  subnets         = ["${aws_subnet.rds1.id}", "${aws_subnet.rds2.id}"]

  tags = {
    Name = "Web ALB"
  }
}

resource "aws_alb_listener" "web_alb_http" {  
  load_balancer_arn = "${aws_alb.web_alb.arn}"  
  port              = "${var.http_port}"  
  protocol          = "HTTP"
  
  default_action {    
    target_group_arn = "${aws_alb_target_group.web_alb_http.arn}"
    type             = "forward"  
  }
}

resource "aws_alb_target_group" "web_alb_http" {
  port        = "${var.http_port}"  
  protocol    = "HTTP"
  vpc_id      = "${aws_vpc.vpc.id}"
  target_type = "instance"

  tags = {
    Name = "Web ALB Target Group"
  }
}

resource "aws_autoscaling_attachment" "alb_asg_attachment" {
  alb_target_group_arn   = "${aws_alb_target_group.web_alb_http.arn}"
  autoscaling_group_name = "${aws_autoscaling_group.web_as_group.id}"
}

# AutoScaling

/*
resource "aws_launch_template" "web_launch_template" {
  name_prefix   = "web_launch_template"
  image_id      = "${var.dev_ami}"
  instance_type = "${var.dev_instance_type}"

  tags = {
    Name = "Web launch template" 
  } 
}
*/
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_launch_configuration" "as_conf" {
  name          = "web_config"
  image_id      = "${data.aws_ami.ubuntu.id}"
  instance_type = "${var.dev_instance_type}"
}
resource "aws_autoscaling_group" "web_as_group" {
  availability_zones = ["${data.aws_availability_zones.available.names[0]}"]
  desired_capacity   = 1
  max_size           = 1
  min_size           = 1

  launch_configuration = "${aws_launch_configuration.as_conf.name}"
}

#-------OUTPUTS ------------

output "Database_Name" {
  value = "${var.dbname}"
}

#Show ELB endpoint