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
  availability_zones = ["${var.availability_zone_a}"]
  desired_capacity   = 1
  max_size           = 1
  min_size           = 1

  launch_configuration = "${aws_launch_configuration.as_conf.name}"
}