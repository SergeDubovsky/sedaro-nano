variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "github_actions_role_arn" {
  description = "The ARN of the IAM role assumed by GitHub Actions"
  type        = string
}