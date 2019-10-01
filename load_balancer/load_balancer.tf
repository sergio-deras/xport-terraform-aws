# ALB
resource "aws_alb" "web_alb" {
  name            = "web-alb"
  security_groups = ["${var.security_group}"]
  subnets         = ["${var.subnets[0]}", "${var.subnets[1]}"]

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
  vpc_id      = "${var.vpc_id}"
  target_type = "instance"

  tags = {
    Name = "Web ALB Target Group"
  }
}
