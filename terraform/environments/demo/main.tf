terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
  # Remote state configuration
  backend "s3" {
    bucket       = "sedaro-nano-terraform-state"
    key          = "demo/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true # Modern S3-native state locking
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

# Data source to get EKS cluster auth token (needed at runtime)
data "aws_eks_cluster_auth" "cluster" {
  name = module.eks_cluster.cluster_name
}

provider "helm" {
  kubernetes {
    host                   = module.eks_cluster.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks_cluster.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

provider "kubernetes" {
  host                   = module.eks_cluster.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_cluster.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
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

  # Launch template configuration (minimal for demo)
  enable_detailed_monitoring             = var.enable_detailed_monitoring
  node_ami_type                          = var.node_ami_type
  node_capacity_type                     = var.node_capacity_type
  node_update_max_unavailable_percentage = var.node_update_max_unavailable_percentage

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
}
