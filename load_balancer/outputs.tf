output "web_alb_target_group" {
  value = "${aws_alb_target_group.web_alb_http}"
}

output "web_alb_http" {
  value = "${aws_alb.web_alb}"
}