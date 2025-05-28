terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.82"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.35"
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

# US-East-1 provider for ACM certificates (required for ALB)
provider "aws" {
  alias  = "us_east_1"
  region = var.cert_region

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
  source       = "../../modules/eks-cluster"
  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region
  vpc_cidr     = var.vpc_cidr
  # Graviton (ARM64) node configuration - primary and only node group
  graviton_instance_types = var.graviton_instance_types
  graviton_desired_size   = var.graviton_desired_size
  graviton_max_size       = var.graviton_max_size
  graviton_min_size       = var.graviton_min_size
  graviton_capacity_type  = var.graviton_capacity_type
  graviton_ami_type       = var.graviton_ami_type

  # Launch template configuration
  enable_detailed_monitoring             = var.enable_detailed_monitoring
  node_update_max_unavailable_percentage = var.node_update_max_unavailable_percentage

  # Access configuration
  github_actions_role_arn = var.github_actions_role_arn
  admin_user_arn          = var.admin_user_arn
  
  # VPC CNI configuration
  enable_vpc_cni_prefix_delegation = var.enable_vpc_cni_prefix_delegation
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
  enable_metrics_server            = var.enable_metrics_server
  enable_cluster_autoscaler        = var.enable_cluster_autoscaler
  enable_vpc_cni_prefix_delegation = var.enable_vpc_cni_prefix_delegation
}

# ECR Repositories for Container Images
module "ecr_repositories" {
  source = "../../modules/ecr"

  project_name               = var.project_name
  environment                = var.environment
  github_actions_role_arn    = var.github_actions_role_arn
  helm_chart_repository_name = "helm-charts/sedaro-nano" # Full path for OCI chart storage
}

################################################################################
# ACM Certificate Module (for custom domain support)
################################################################################

module "acm_certificate" {
  source = "../../modules/acm-certificate"

  enable_custom_domain = var.enable_custom_domain
  domain_name          = var.domain_name
  host_name            = var.host_name
  environment          = var.environment
  project_name         = var.project_name
  include_wildcard     = var.include_wildcard

  providers = {
    aws.us_east_1 = aws.us_east_1
  }
}
