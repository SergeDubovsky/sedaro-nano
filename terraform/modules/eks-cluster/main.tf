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
  cluster_version = "1.32" # Last version with AL2 AMI support (AL2 deprecated Nov 26, 2025)

  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true
  authentication_mode            = "API_AND_CONFIG_MAP"

  # Allow the GitHub Actions role to access the cluster
  access_entries = merge(
    {
      github_actions_role = {
        principal_arn = var.github_actions_role_arn
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
    main = { # ================================
      # Node Group Basic Configuration
      # ================================
      name            = "${local.name}-main"
      use_name_prefix = true # Use name prefix with timestamp for uniqueness and avoiding conflicts      # ================================
      # Instance & Capacity Configuration  
      # ================================
      instance_types = var.node_instance_types
      capacity_type  = var.node_capacity_type # Configurable: ON_DEMAND or SPOT
      ami_type       = var.node_ami_type      # Configurable AMI type
      # Note: AL2 AMIs deprecated after Nov 26, 2025. Use AL2023_x86_64_STANDARD or BOTTLEROCKET_*
      # From K8s 1.33+, only AL2023 and Bottlerocket AMIs will be available

      # ================================
      # Auto Scaling Configuration
      # ================================
      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size # ================================
      # Launch Template Configuration
      # ================================
      create_launch_template          = true
      launch_template_name            = "${local.name}-node-template"
      launch_template_description     = "Production-optimized launch template for ${local.name} EKS managed node group"
      launch_template_use_name_prefix = true # Use prefix for uniqueness and avoiding conflicts

      # Enhanced launch template tags for better resource tracking
      launch_template_tags = merge(local.tags, {
        Component      = "launch-template"
        NodeGroup      = "main"
        Purpose        = "eks-worker-nodes"
        CostCenter     = var.environment
        LaunchTemplate = "${local.name}-node-template"
      }) 

      # ================================
      # Security Configuration (IMDS)
      # ================================
      metadata_options = {
        http_endpoint               = "enabled"  # Enable metadata service
        http_tokens                 = "required" # Require IMDSv2 tokens (security best practice)
        http_put_response_hop_limit = 2          # Limit metadata access to direct requests
        instance_metadata_tags      = "enabled"  # Enable instance tags in metadata
      }

      # ================================
      # Monitoring & Observability
      # ================================
      enable_monitoring = var.enable_detailed_monitoring # Configurable monitoring

      # ================================
      # Network Performance Optimization
      # ================================
      # Enhanced networking for better pod-to-pod communication
      enable_bootstrap_user_data = true
      pre_bootstrap_user_data    = <<-EOT
        #!/bin/bash
        # Optimize network performance for Kubernetes workloads
        echo 'net.core.rmem_default = 262144' >> /etc/sysctl.conf
        echo 'net.core.rmem_max = 16777216' >> /etc/sysctl.conf
        echo 'net.core.wmem_default = 262144' >> /etc/sysctl.conf
        echo 'net.core.wmem_max = 16777216' >> /etc/sysctl.conf
        sysctl -p
        
        # Set optimal container runtime settings
        mkdir -p /etc/containerd/conf.d
        cat > /etc/containerd/conf.d/99-custom.toml << EOF
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
  SystemdCgroup = true
EOF
        systemctl restart containerd
      EOT

      # ================================
      # Rolling Update Configuration
      # ================================
      update_config = {
        max_unavailable_percentage = var.node_update_max_unavailable_percentage # Configurable update strategy
      }

      # ================================
      # Kubernetes Configuration
      # ================================
      # Node labels for workload scheduling
      labels = merge({
        # Standard labels
        Environment = var.environment
        NodeGroup   = "main"
        Project     = var.project_name
        ManagedBy   = "terraform"

        # EKS-specific labels
        "node.kubernetes.io/instance-type" = join(",", var.node_instance_types)
        "node.kubernetes.io/capacity-type" = lower(var.node_capacity_type)

        # Custom application labels
        "sedaro.io/workload-type"  = "general"
        "sedaro.io/cost-optimized" = var.node_capacity_type == "SPOT" ? "true" : "false"
      }, local.tags)

      # No taints for main node group (accepts all workloads)
      taints = {} # ================================
      # Resource Tags
      # ================================
      tags = merge(local.tags, {
        Component    = "node-group"
        NodeGroup    = "main"
        CapacityType = lower(var.node_capacity_type)
        Purpose      = "eks-worker-nodes"
        AutoScaling  = "enabled"
        Monitoring   = var.enable_detailed_monitoring ? "enabled" : "disabled"
        Storage      = "eks-default" # Using EKS default storage (20GB gp2)
      })
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
