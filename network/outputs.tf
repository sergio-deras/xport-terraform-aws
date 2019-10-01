output "vpc" {
  value = "${aws_vpc.vpc}"
}

output "rds_subnetgroup" {
  value = "${aws_db_subnet_group.rds_subnetgroup}"
}

output "web_sg" {
  value = "${aws_security_group.web_sg}"
}

output "app_sg" {
  value = "${aws_security_group.app_sg}"
}

output "rds_sg" {
  value = "${aws_security_group.RDS}"
}


output "web_subnet" {
  value = "${aws_subnet.web_subnet}"
}

output "app_subnet" {
  value = "${aws_subnet.app_subnet}"
}

output "rds1_subnet" {
  value = "${aws_subnet.rds1}"
}

output "rds2_subnet" {
  value = "${aws_subnet.rds2}"
}