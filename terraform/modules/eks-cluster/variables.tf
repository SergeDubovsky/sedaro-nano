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

variable "github_actions_role_arn" {
  description = "The ARN of the IAM role assumed by GitHub Actions for EKS access. This should be supplied via a GitHub repository secret (e.g., GITHUB_ACTIONS_ROLE_ARN) and passed as the TF_VAR_github_actions_role_arn environment variable."
  type        = string
}

variable "admin_user_arn" {
  description = "The ARN of an IAM user or role to grant EKS cluster admin access. This should be supplied via a GitHub repository secret (e.g., ADMIN_USER_ARN) and passed as the TF_VAR_admin_user_arn environment variable. If empty or not provided, no admin user access entry will be created."
  type        = string
  default     = ""
}

# ================================
# Launch Template Configuration
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

  validation {
    condition     = var.node_update_max_unavailable_percentage >= 1 && var.node_update_max_unavailable_percentage <= 100
    error_message = "Max unavailable percentage must be between 1 and 100"
  }
}

# ================================
# Graviton (ARM64) Node Group Variables - Primary Node Group
# ================================

variable "graviton_instance_types" {
  description = "EC2 instance types for Graviton (ARM64) EKS nodes - primary node group"
  type        = list(string)
  default     = ["m6g.medium"] # Cost-optimized Graviton instances
}

variable "graviton_desired_size" {
  description = "Desired number of Graviton nodes"
  type        = number
  default     = 1
}

variable "graviton_max_size" {
  description = "Maximum number of Graviton nodes"
  type        = number
  default     = 3
}

variable "graviton_min_size" {
  description = "Minimum number of Graviton nodes"
  type        = number
  default     = 1 # Must be at least 1 when Graviton is the only node group
}

variable "graviton_capacity_type" {
  description = "Type of capacity for Graviton nodes. Valid values: ON_DEMAND, SPOT"
  type        = string
  default     = "SPOT" # Default to SPOT for maximum cost savings

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.graviton_capacity_type)
    error_message = "Graviton capacity type must be either ON_DEMAND or SPOT"
  }
}

variable "graviton_ami_type" {
  description = "Type of Amazon Machine Image (AMI) for Graviton nodes - primary node group"
  type        = string
  default     = "AL2023_ARM_64_STANDARD"

  validation {
    condition = contains([
      "AL2023_ARM_64_STANDARD",
      "BOTTLEROCKET_ARM_64",
      "BOTTLEROCKET_ARM_64_NVIDIA"
    ], var.graviton_ami_type)
    error_message = "Graviton AMI type must be a valid ARM64 AMI type"
  }
}

# ================================
# VPC CNI Configuration
# ================================

variable "enable_vpc_cni_prefix_delegation" {
  description = "Enable VPC CNI prefix delegation for higher pod density"
  type        = bool
  default     = true
}
