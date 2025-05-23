output "aws_load_balancer_controller_status" {
  description = "Status of the AWS Load Balancer Controller Helm release"
  value       = helm_release.aws_load_balancer_controller.status
}

output "aws_load_balancer_controller_version" {
  description = "Version of the AWS Load Balancer Controller"
  value       = helm_release.aws_load_balancer_controller.version
}

output "cluster_info" {
  description = "Information about the EKS cluster from infrastructure state"
  value = {
    cluster_name = data.terraform_remote_state.infrastructure.outputs.cluster_name
    cluster_arn  = data.terraform_remote_state.infrastructure.outputs.cluster_arn
    vpc_id       = data.terraform_remote_state.infrastructure.outputs.vpc_id
  }
}
