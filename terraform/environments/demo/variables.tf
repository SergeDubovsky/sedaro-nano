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

variable "cert_region" {
  type        = string
  description = "AWS region for ACM certificates (must be us-east-1 for ALB)"
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

variable "enable_vpc_cni_prefix_delegation" {
  description = "Enable VPC CNI prefix delegation for higher pod density"
  type        = bool
  default     = true
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
  default     = ["m6g.large", "m6g.xlarge"] # Larger Graviton3 instances for higher pod density
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

# ================================
# Custom Domain Configuration
# ================================

variable "enable_custom_domain" {
  description = "Enable custom domain and certificate provisioning"
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "The domain name (e.g., k8sdemo.click)"
  type        = string
  default     = ""
}

variable "host_name" {
  description = "The hostname prefix (e.g., sedaro)"
  type        = string
  default     = ""
}

variable "include_wildcard" {
  description = "Include wildcard certificate for subdomains"
  type        = bool
  default     = false
}
