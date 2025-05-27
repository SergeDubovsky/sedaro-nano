# EKS Cluster Outputs
output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks_cluster.cluster_endpoint
  sensitive   = true
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = module.eks_cluster.cluster_name
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks_cluster.cluster_certificate_authority_data
  sensitive   = true
}

output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = module.eks_cluster.cluster_arn
}

output "cluster_version" {
  description = "The Kubernetes version for the EKS cluster"
  value       = module.eks_cluster.cluster_version
}

# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC where the cluster is deployed"
  value       = module.eks_cluster.vpc_id
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.eks_cluster.private_subnets
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.eks_cluster.public_subnets
}

# IAM Outputs
output "aws_load_balancer_controller_role_arn" {
  description = "ARN of the AWS Load Balancer Controller IAM role"
  value       = module.eks_cluster.aws_load_balancer_controller_role_arn
}

# kubectl Configuration
output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = module.eks_cluster.kubectl_config_command
}

# Addon Status
output "metrics_server_enabled" {
  description = "Whether metrics server is enabled"
  value       = module.eks_addons.metrics_server_enabled
}

output "cluster_autoscaler_enabled" {
  description = "Whether cluster autoscaler is enabled"
  value       = module.eks_addons.cluster_autoscaler_enabled
}

# ECR Repositories
output "ecr_repository_urls" {
  description = "URLs of the ECR repositories"
  value       = module.ecr_repositories.repository_urls
}

output "ecr_app_repository_url" {
  description = "The URL of the ECR repository for the application image"
  value       = module.ecr_repositories.repository_urls["backend"]
}

output "ecr_web_repository_url" {
  description = "The URL of the ECR repository for the web image"
  value       = module.ecr_repositories.repository_urls["frontend"]
}

output "ecr_registry_id" {
  description = "ECR Registry ID"
  value       = module.ecr_repositories.registry_id
}
