# Backup provider configuration using config_path approach
# Use this if the exec provider authentication fails

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.10"
    }
  }

  # Remote state storage in S3
  backend "s3" {
    bucket       = "sedaro-nano-terraform-state"
    key          = "demo/terraform-addons.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}

# Data source to read the infrastructure state from Stage 1
data "terraform_remote_state" "infrastructure" {
  backend = "s3"
  config = {
    bucket = "sedaro-nano-terraform-state"
    key    = "demo/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Stage       = "addons"
    }
  }
}

# Alternative provider configuration using config_path
provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}
