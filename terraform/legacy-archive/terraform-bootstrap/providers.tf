terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  # AWS credentials will be provided by environment variables:
  # AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, and optionally AWS_SESSION_TOKEN

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = "management"
      ManagedBy   = "terraform"
    }
  }
}
