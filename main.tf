provider "aws" {
  region = "${var.aws_region}"
}

data "aws_availability_zones" "available" {}

module "network" {
  source                 = "./network"
  cidrs                  = "${var.cidrs}"
  aws_availability_zones = "${data.aws_availability_zones.available.names}"
  db_port                = "${var.db_port}"
  ssh_port               = "${var.ssh_port}"
  http_port              = "${var.http_port}"
  access_cidr            = "${var.access_cidr}"
}

module "auto_scaling" {
  source            = "./auto_scaling"
  subnet            = "${module.network.web_subnet}"
  security_group    = "${module.network.web_sg.id}"
  dev_instance_type = "${var.dev_instance_type}"
  dev_ami           = "${var.dev_ami}"
}

module "load_balancer" {
  source         = "./load_balancer"
  security_group = "${module.network.web_sg.id}"
  subnets        = ["${module.network.rds1_subnet.id}", "${module.network.rds2_subnet.id}"]
  http_port      = "${var.http_port}"
  vpc_id         = "${module.network.vpc.id}"
}

module "name" {
  source = "./instances"
  key_name          = "${var.key_name}"
  public_key_path   = "${var.public_key_path}"
  dev_instance_type = "${var.dev_instance_type}"
  dev_ami           = "${var.dev_ami}"
  security_group_id = "${module.network.app_sg.id}"
  subnet_id         = "${module.network.app_subnet.id}"
}

#RDS
resource "aws_db_instance" "db" {
  allocated_storage      = 10
  engine                 = "mysql"
  port                   = "${var.db_port}"
  instance_class         = "${var.db_instance_class}"
  name                   = "${var.dbname}"
  username               = "${var.dbuser}"
  password               = "${var.dbpassword}"
  db_subnet_group_name   = "${module.network.rds_subnetgroup.name}"
  vpc_security_group_ids = ["${module.network.rds_sg.id}"]
  skip_final_snapshot    = true
}

# Attach ASG with ELB
resource "aws_autoscaling_attachment" "alb_asg_attachment" {
  alb_target_group_arn   = "${module.load_balancer.web_alb_target_group.arn}"
  autoscaling_group_name = "${module.auto_scaling.web_as_group.id}"
}