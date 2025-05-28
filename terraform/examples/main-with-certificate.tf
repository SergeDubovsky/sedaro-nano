# Example integration in main Terraform configuration
# File: terraform/environments/prod/main.tf

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Default AWS provider (your main region)
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "sedaro-nano"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# US-East-1 provider for ACM certificates (required for ALB)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
  
  default_tags {
    tags = {
      Project     = "sedaro-nano"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# Certificate Module
module "acm_certificate" {
  source = "../../modules/acm-certificate"
  
  enable_custom_domain = var.enable_custom_domain
  domain_name         = var.domain_name
  host_name           = var.host_name
  environment         = var.environment
  project_name        = "sedaro-nano"
  include_wildcard    = false
  
  providers = {
    aws.us_east_1 = aws.us_east_1
  }
}

# Your existing EKS/infrastructure modules here...
# module "eks" { ... }
# module "networking" { ... }

# Output certificate ARN for GitHub Actions
output "certificate_arn" {
  description = "ACM Certificate ARN for the custom domain"
  value       = module.acm_certificate.certificate_arn
}

output "certificate_domain" {
  description = "Domain name of the certificate"
  value       = module.acm_certificate.certificate_domain
}
