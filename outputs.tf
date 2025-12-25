output "alb_dns_name" {
  value = aws_lb.alb.dns_name
}

output "frontend_url" {
  value = "http://${aws_lb.alb.dns_name}"
}

output "grafana_url" {
  value = "http://${aws_instance.manager.public_ip}:3000"
}

output "prometheus_url" {
  value = "http://${aws_instance.manager.public_ip}:9090"
}
