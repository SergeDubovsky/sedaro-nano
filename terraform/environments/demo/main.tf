terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote state configuration
  backend "s3" {
    bucket         = "sedaro-nano-terraform-state"
    key            = "demo/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "sedaro-nano-terraform-state-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

################################################################################
# EKS Cluster Module
################################################################################

module "eks_cluster" {
  source = "../../modules/eks-cluster"

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region
  vpc_cidr     = var.vpc_cidr

  # Node configuration
  node_instance_types = var.node_instance_types
  node_desired_size   = var.node_desired_size
  node_max_size       = var.node_max_size
  node_min_size       = var.node_min_size

  # Access configuration
  github_actions_role_arn = var.github_actions_role_arn
  admin_user_arn          = var.admin_user_arn
}

################################################################################
# EKS Addons Module
################################################################################

module "eks_addons" {
  source = "../../modules/eks-addons"

  project_name                          = var.project_name
  environment                           = var.environment
  aws_region                            = var.aws_region
  cluster_name                          = module.eks_cluster.cluster_name
  aws_load_balancer_controller_role_arn = module.eks_cluster.aws_load_balancer_controller_role_arn

  # Addon configuration
  enable_metrics_server     = var.enable_metrics_server
  enable_cluster_autoscaler = var.enable_cluster_autoscaler

  depends_on = [module.eks_cluster]
}
