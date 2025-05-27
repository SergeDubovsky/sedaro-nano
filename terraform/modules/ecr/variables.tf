variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "github_actions_role_arn" {
  description = "ARN of the GitHub Actions IAM role that needs access to ECR"
  type        = string
}

variable "helm_chart_repository_name" {
  description = "Name for the ECR repository to store Helm charts. Can include slashes for path-like names."
  type        = string
  default     = "helm-charts"
  # If you want it to be project specific by default, you could use a local or pass it in fully formed.
  # For example, in the root module you could set it to "helm-charts/${var.project_name}"
}