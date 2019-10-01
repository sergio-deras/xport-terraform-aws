output "ELB_Endpoint" {
  value = "${module.load_balancer.web_alb_http.dns_name}"
}