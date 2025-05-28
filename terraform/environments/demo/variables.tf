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

# Node Configuration
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
# Launch Template Configuration (Simplified for Demo)
# ================================
# Note: Volume configuration variables removed for demo simplicity
# EKS will use defaults: 20GB gp2 root volume

variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring for worker nodes"
  type        = bool
  default     = true
}

variable "node_ami_type" {
  description = "Type of Amazon Machine Image (AMI) for worker nodes. AL2023 recommended (AL2 deprecated Nov 2025)"
  type        = string
  default     = "AL2023_x86_64_STANDARD" # Future-proof: AL2 deprecated after Nov 26, 2025
}

variable "node_capacity_type" {
  description = "Type of capacity associated with the EKS Node Group. Valid values: ON_DEMAND, SPOT"
  type        = string
  default     = "SPOT"
}

variable "node_update_max_unavailable_percentage" {
  description = "Maximum percentage of nodes unavailable during update"
  type        = number
  default     = 25
}

# ================================
# Graviton (ARM64) Node Configuration
# ================================

variable "graviton_instance_types" {
  description = "EC2 instance types for Graviton (ARM64) EKS nodes"
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
  default     = 0 # Can scale to zero when not needed
}

variable "graviton_capacity_type" {
  description = "Type of capacity for Graviton nodes"
  type        = string
  default     = "SPOT" # Use SPOT for maximum cost savings
}

variable "graviton_ami_type" {
  description = "AMI type for Graviton nodes"
  type        = string
  default     = "AL2023_ARM_64_STANDARD"
}

variable "graviton_taint_arm_workloads" {
  description = "Whether to taint Graviton nodes for ARM64-only workloads"
  type        = bool
  default     = false # Allow mixed scheduling for demo
}
