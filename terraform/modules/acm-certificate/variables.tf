# Variables for ACM Certificate Module

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

variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
  default     = "sedaro-nano"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "include_wildcard" {
  description = "Include wildcard certificate for subdomains"
  type        = bool
  default     = false
}
