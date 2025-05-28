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
  version = "~> 5.17"

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
  version = "~> 20.31"

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
  ) # EKS Managed Node Group(s) - Graviton-only configuration
  eks_managed_node_group_defaults = {
    instance_types = var.graviton_instance_types

    # We are using the IRSA created below for permissions
    # However, we have to deploy with the policy attached FIRST (when creating a fresh cluster)
    # and then turn this off after the cluster/node group is created. Without this initial policy,
    # the VPC CNI fails to assign IPs and nodes cannot join the cluster
    # See https://github.com/aws/containers-roadmap/issues/1666 for more context
    iam_role_attach_cni_policy = true
  }

  eks_managed_node_groups = {
    # Single ARM64 Graviton node group for cost optimization
    main = { # ================================
      # Node Group Basic Configuration
      # ================================
      name            = "${local.name}-main"
      use_name_prefix = true

      # ================================
      # Instance & Capacity Configuration (ARM64 Graviton)
      # ================================
      instance_types = var.graviton_instance_types
      capacity_type  = var.graviton_capacity_type # Usually SPOT for cost optimization
      ami_type       = var.graviton_ami_type      # AL2023_ARM_64_STANDARD

      # ================================
      # Auto Scaling Configuration
      # ================================
      min_size     = var.graviton_min_size
      max_size     = var.graviton_max_size
      desired_size = var.graviton_desired_size

      # ================================
      # Launch Template Configuration
      # ================================
      create_launch_template          = true
      launch_template_name            = "${local.name}-main-lt"
      launch_template_description     = "ARM64 Graviton launch template for ${local.name} EKS managed node group"
      launch_template_use_name_prefix = true

      launch_template_tags = merge(local.tags, {
        Component      = "launch-template"
        NodeGroup      = "main"
        Architecture   = "arm64"
        Purpose        = "eks-worker-nodes-graviton"
        CostCenter     = var.environment
        LaunchTemplate = "${local.name}-main-lt"
      })

      # ================================
      # Security Configuration (IMDS)
      # ================================
      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required" # IMDSv2 required
        http_put_response_hop_limit = 2
        instance_metadata_tags      = "enabled"
      }

      # ================================
      # Monitoring & Observability
      # ================================
      enable_monitoring = var.enable_detailed_monitoring

      # ================================
      # Network Performance Optimization for ARM64
      # ================================
      enable_bootstrap_user_data = true
      pre_bootstrap_user_data    = <<-EOT
        #!/bin/bash
        # ARM64-specific optimizations
        echo 'net.core.rmem_default = 262144' >> /etc/sysctl.conf
        echo 'net.core.rmem_max = 16777216' >> /etc/sysctl.conf
        echo 'net.core.wmem_default = 262144' >> /etc/sysctl.conf
        echo 'net.core.wmem_max = 16777216' >> /etc/sysctl.conf
        sysctl -p
        
        # Container runtime optimization for ARM64
        mkdir -p /etc/containerd/conf.d
        cat > /etc/containerd/conf.d/99-graviton.toml << EOF
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
  SystemdCgroup = true
  # ARM64-specific runtime optimizations
EOF
        systemctl restart containerd
      EOT

      # ================================
      # Rolling Update Configuration
      # ================================
      update_config = {
        max_unavailable_percentage = var.node_update_max_unavailable_percentage
      }

      # ================================
      # Kubernetes Configuration
      # ================================
      labels = merge({
        # Standard labels
        Environment = var.environment
        NodeGroup   = "main"
        Project     = var.project_name
        ManagedBy   = "terraform"

        # Custom application labels (removed reserved prefixes)
        "sedaro.io/workload-type"  = "general"
        "sedaro.io/architecture"   = "arm64"
        "sedaro.io/cost-optimized" = "true"
        "sedaro.io/node-type"      = "graviton"
      }, local.tags)

      # No taints for the main (and only) node group - accepts all workloads
      taints = {}

      # ================================
      # Resource Tags
      # ================================
      tags = merge(local.tags, {
        Component    = "node-group"
        NodeGroup    = "main"
        Architecture = "arm64"
        CapacityType = lower(var.graviton_capacity_type)
        Purpose      = "eks-worker-nodes-graviton"
        AutoScaling  = "enabled"
        Monitoring   = var.enable_detailed_monitoring ? "enabled" : "disabled"
        Storage      = "eks-default"
        CostSavings  = "graviton-optimized"
      })
    }
  }

  tags = local.tags
}

################################################################################
# VPC CNI Configuration for Enhanced Pod Density
################################################################################

resource "aws_eks_addon" "vpc_cni" {
  cluster_name             = module.eks.cluster_name
  addon_name               = "vpc-cni"
  addon_version            = "v1.19.0-eksbuild.1" # Latest version that supports prefix delegation
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  service_account_role_arn = aws_iam_role.vpc_cni_role.arn

  configuration_values = jsonencode({
    enableNetworkPolicy = "false"
    env = {
      # Enable IP prefix delegation for higher pod density
      ENABLE_PREFIX_DELEGATION = "true"
      # Warm prefix target - number of prefixes to keep available
      WARM_PREFIX_TARGET = "1"
      # Warm IP target per ENI
      WARM_IP_TARGET = "3"
      # Enable pod ENI for better performance (optional)
      ENABLE_POD_ENI = "false"
    }
  })

  depends_on = [
    module.eks.eks_managed_node_groups
  ]

  tags = local.tags
}

# IAM Role for VPC CNI with enhanced permissions
resource "aws_iam_role" "vpc_cni_role" {
  name = "${local.name}-vpc-cni-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Condition = {
          StringEquals = {
            "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-node"
            "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
      }
    ]
  })

  tags = local.tags
}

# Attach CNI policy with prefix delegation permissions
resource "aws_iam_role_policy_attachment" "vpc_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.vpc_cni_role.name
}

# Additional policy for prefix delegation
resource "aws_iam_role_policy" "vpc_cni_prefix_delegation" {
  name = "${local.name}-vpc-cni-prefix-delegation"
  role = aws_iam_role.vpc_cni_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:AttachNetworkInterface",
          "ec2:DeleteNetworkInterface",
          "ec2:DetachNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeInstances",
          "ec2:ModifyNetworkInterfaceAttribute",
          "ec2:AssignPrivateIpAddresses",
          "ec2:UnassignPrivateIpAddresses",
          # Prefix delegation specific permissions
          "ec2:AssignIpv6Addresses",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs",
          "ec2:DescribeNetworkInterfaceAttribute"
        ]
        Resource = "*"
      }
    ]
  })
}

################################################################################
# AWS Load Balancer Controller IRSA Role
# Note: The actual Helm deployment is in terraform-addons/
################################################################################

module "aws_load_balancer_controller_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.48"

  role_name = "${local.name}-alb-controller"

  attach_load_balancer_controller_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  tags = local.tags
}
