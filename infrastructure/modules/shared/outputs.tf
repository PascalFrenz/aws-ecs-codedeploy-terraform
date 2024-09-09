output "alb_security_group_id" {
  value = aws_security_group.lb.id
}

output "alb_arn" {
  value = aws_lb.alb.arn
}

output "alb_http_listener_arn" {
  value = aws_lb_listener.http.arn
}

output "alb_dns_name" {
  value = aws_lb.alb.dns_name
}
