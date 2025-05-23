locals {
  name = "${var.project_name}-${var.environment}"

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Stage       = "addons"
  }
}

################################################################################
# AWS Load Balancer Controller
################################################################################

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.13.2"

  set {
    name  = "clusterName"
    value = data.terraform_remote_state.infrastructure.outputs.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = data.terraform_remote_state.infrastructure.outputs.aws_load_balancer_controller_role_arn
  }

  # Wait for the cluster to be ready
  depends_on = [
    data.terraform_remote_state.infrastructure
  ]
}

################################################################################
# Other Add-ons can be added here
################################################################################

# Example: Metrics Server
# resource "helm_release" "metrics_server" {
#   name       = "metrics-server"
#   repository = "https://kubernetes-sigs.github.io/metrics-server/"
#   chart      = "metrics-server"
#   namespace  = "kube-system"
#   version    = "3.12.0"
# }

# Example: Cluster Autoscaler
# resource "helm_release" "cluster_autoscaler" {
#   name       = "cluster-autoscaler"
#   repository = "https://kubernetes.github.io/autoscaler"
#   chart      = "cluster-autoscaler"
#   namespace  = "kube-system"
#   version    = "9.29.0"
#
#   set {
#     name  = "cloudProvider"
#     value = "aws"
#   }
#
#   set {
#     name  = "awsRegion"
#     value = var.aws_region
#   }
# }
