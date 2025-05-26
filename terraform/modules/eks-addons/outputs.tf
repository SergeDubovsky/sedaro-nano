output "aws_load_balancer_controller_release_name" {
  description = "Name of the AWS Load Balancer Controller Helm release"
  value       = helm_release.aws_load_balancer_controller.name
}

output "metrics_server_enabled" {
  description = "Whether metrics server is enabled"
  value       = var.enable_metrics_server
}

output "cluster_autoscaler_enabled" {
  description = "Whether cluster autoscaler is enabled"
  value       = var.enable_cluster_autoscaler
}
