output "manager_public_ip" {
  value = aws_instance.manager[0].public_ip
}

output "grafana_url" {
  value = "http://${aws_instance.manager[0].public_ip}:3000"
}

output "prometheus_url" {
  value = "http://${aws_instance.manager[0].public_ip}:9090"
}

output "frontend_url" {
  value = "http://${aws_instance.manager[0].public_ip}"
}
