# Variables for certificate integration
# File: terraform/environments/prod/variables.tf

variable "aws_region" {
  description = "AWS region for main resources"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

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
