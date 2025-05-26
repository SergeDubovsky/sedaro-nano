data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

data "aws_caller_identity" "current" {}

locals {
  name = "${var.project_name}-${var.environment}"

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

################################################################################
# VPC
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name
  cidr = var.vpc_cidr

  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  public_subnets  = [for k, v in slice(data.aws_availability_zones.available.names, 0, 2) : cidrsubnet(var.vpc_cidr, 8, k)]
  private_subnets = [for k, v in slice(data.aws_availability_zones.available.names, 0, 2) : cidrsubnet(var.vpc_cidr, 8, k + 10)]

  enable_nat_gateway   = true
  single_nat_gateway   = true # Cost optimization: single NAT gateway
  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    "kubernetes.io/role/elb"              = 1
    "kubernetes.io/cluster/${local.name}" = "owned"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"     = 1
    "kubernetes.io/cluster/${local.name}" = "owned"
  }

  tags = local.tags
}

################################################################################
# EKS
################################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = local.name
  cluster_version = "1.32"

  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true

  # Allow the GitHub Actions role to access the cluster
  access_entries = merge(
    {
      github_actions_role = {
        kubernetes_groups = [] # No specific Kubernetes groups needed for admin access
        principal_arn     = var.github_actions_role_arn
        policy_associations = {
          admin_policy = {
            policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
            access_scope = {
              type = "cluster"
            }
          }
        }
      }
    },
    var.admin_user_arn != "" ? {
      admin_user = {
        kubernetes_groups = [] # Granting admin via policy association
        principal_arn     = var.admin_user_arn
        policy_associations = {
          admin_policy = {
            policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
            access_scope = {
              type = "cluster"
            }
          }
        }
      }
    } : {}
  )

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    instance_types = var.node_instance_types

    # We are using the IRSA created below for permissions
    # However, we have to deploy with the policy attached FIRST (when creating a fresh cluster)
    # and then turn this off after the cluster/node group is created. Without this initial policy,
    # the VPC CNI fails to assign IPs and nodes cannot join the cluster
    # See https://github.com/aws/containers-roadmap/issues/1666 for more context
    iam_role_attach_cni_policy = true
  }
  eks_managed_node_groups = {
    main = {
      name            = "${local.name}-main"
      use_name_prefix = false # Use exact name without timestamp suffix

      instance_types = var.node_instance_types
      capacity_type  = "SPOT" # Cost optimization: use SPOT instances

      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size

      # Launch template configuration
      launch_template_name        = "${local.name}-main"
      launch_template_description = "Launch template for ${local.name} EKS managed node group"

      update_config = {
        max_unavailable_percentage = 33 # or set `max_unavailable`
      }

      labels = {
        Environment = var.environment
        NodeGroup   = "main"
      }

      tags = local.tags
    }
  }

  tags = local.tags
}

################################################################################
# AWS Load Balancer Controller IRSA Role
# Note: The actual Helm deployment is in terraform-addons/
################################################################################

module "aws_load_balancer_controller_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "${local.name}-aws-load-balancer-controller"

  attach_load_balancer_controller_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  tags = local.tags
}
