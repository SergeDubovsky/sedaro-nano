# Project Configuration
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "sedaro-nano"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "demo"
}

variable "aws_region" {
  type        = string
  description = "AWS region for cluster and S3 state backend"
  default     = "us-east-1"
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# Access Configuration
variable "github_actions_role_arn" {
  description = "The ARN of the IAM role assumed by GitHub Actions for EKS access"
  type        = string
}

variable "admin_user_arn" {
  description = "The ARN of an IAM user or role to grant EKS cluster admin access"
  type        = string
  default     = ""
}

# Addon Configuration
variable "enable_metrics_server" {
  description = "Enable metrics server addon"
  type        = bool
  default     = true
}

variable "enable_cluster_autoscaler" {
  description = "Enable cluster autoscaler addon"
  type        = bool
  default     = false
}

# ================================
# Launch Template Configuration (Graviton-only)
# ================================

variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring for worker nodes"
  type        = bool
  default     = true
}

variable "node_update_max_unavailable_percentage" {
  description = "Maximum percentage of nodes unavailable during update"
  type        = number
  default     = 25
}

# ================================
# Graviton (ARM64) Node Configuration - Primary Node Group
# ================================

variable "graviton_instance_types" {
  description = "EC2 instance types for Graviton (ARM64) EKS nodes - primary and only node group"
  type        = list(string)
  default     = ["m6g.medium", "m6g.large"] # Graviton3 instances for cost efficiency
}

variable "graviton_desired_size" {
  description = "Desired number of Graviton nodes"
  type        = number
  default     = 1 # Start with 1 for testing
}

variable "graviton_max_size" {
  description = "Maximum number of Graviton nodes"
  type        = number
  default     = 3
}

variable "graviton_min_size" {
  description = "Minimum number of Graviton nodes"
  type        = number
  default     = 1 # Must be at least 1 since this is the only node group
}

variable "graviton_capacity_type" {
  description = "Type of capacity for Graviton nodes"
  type        = string
  default     = "SPOT" # Use SPOT for maximum cost savings
}

variable "graviton_ami_type" {
  description = "AMI type for Graviton nodes - primary and only node group"
  type        = string
  default     = "AL2023_ARM_64_STANDARD"
}
