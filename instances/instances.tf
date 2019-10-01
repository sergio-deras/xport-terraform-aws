# key pair
resource "aws_key_pair" "auth" {
  key_name   = "${var.key_name}"
  public_key = "${file(var.public_key_path)}"
}

# server
resource "aws_instance" "app" {
  instance_type = "${var.dev_instance_type}"
  ami           = "${var.dev_ami}"

  tags = {
    Name = "wordpress-instance"
  }

  key_name               = "${aws_key_pair.auth.id}"
  vpc_security_group_ids = ["${var.security_group_id}"]
  subnet_id              = "${var.subnet_id}"
}