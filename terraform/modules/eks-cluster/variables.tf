variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  type        = string
  description = "AWS region for cluster and S3 state backend"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones for the EKS cluster"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "node_instance_types" {
  description = "EC2 instance types for EKS nodes"
  type        = list(string)
  default     = ["t3.small"] # Cost-optimized for demo
}

variable "node_desired_size" {
  description = "Desired number of nodes"
  type        = number
  default     = 1 # Minimal for demo
}

variable "node_max_size" {
  description = "Maximum number of nodes"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of nodes"
  type        = number
  default     = 1
}

variable "github_actions_role_arn" {
  description = "The ARN of the IAM role assumed by GitHub Actions for EKS access. This should be supplied via a GitHub repository secret (e.g., GITHUB_ACTIONS_ROLE_ARN) and passed as the TF_VAR_github_actions_role_arn environment variable."
  type        = string
}

variable "admin_user_arn" {
  description = "The ARN of an IAM user or role to grant EKS cluster admin access. This should be supplied via a GitHub repository secret (e.g., ADMIN_USER_ARN) and passed as the TF_VAR_admin_user_arn environment variable. If empty or not provided, no admin user access entry will be created."
  type        = string
  default     = ""
}
