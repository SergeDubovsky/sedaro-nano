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
  # Let Helm pick the latest available version

  set {
    name  = "clusterName"
    value = var.cluster_name
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
    value = var.aws_load_balancer_controller_role_arn
  }
}

################################################################################
# Other Add-ons can be added here
################################################################################

# Example: Metrics Server
resource "helm_release" "metrics_server" {
  count = var.enable_metrics_server ? 1 : 0

  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"
  version    = "3.12.2"

  set {
    name  = "args"
    value = "{--kubelet-insecure-tls}"
  }
}

# Example: Cluster Autoscaler
resource "helm_release" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  namespace  = "kube-system"
  version    = "9.43.0"

  set {
    name  = "cloudProvider"
    value = "aws"
  }

  set {
    name  = "awsRegion"
    value = var.aws_region
  }
  set {
    name  = "autoDiscovery.clusterName"
    value = var.cluster_name
  }
}

################################################################################
# VPC CNI Environment Variables for Enhanced Pod Density
################################################################################

# Configure VPC CNI for higher pod density using ConfigMap
resource "kubernetes_config_map" "vpc_cni_config" {
  count = var.enable_vpc_cni_prefix_delegation ? 1 : 0

  metadata {
    name      = "amazon-vpc-cni"
    namespace = "kube-system"
  }

  data = {
    # Enable prefix delegation for higher pod density
    enable_prefix_delegation = "true"
    # Warm prefix target - number of prefixes to keep available
    warm_prefix_target = "1"
    # Warm IP target per ENI
    warm_ip_target = "3"
    # Enable pod ENI for better performance (optional)
    enable_pod_eni = "false"
  }
}

# Patch the aws-node DaemonSet to use prefix delegation
resource "null_resource" "vpc_cni_patch" {
  count = var.enable_vpc_cni_prefix_delegation ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      kubectl patch daemonset aws-node -n kube-system -p '{
        "spec": {
          "template": {
            "spec": {
              "containers": [{
                "name": "aws-node",
                "env": [
                  {"name": "ENABLE_PREFIX_DELEGATION", "value": "true"},
                  {"name": "WARM_PREFIX_TARGET", "value": "1"},
                  {"name": "WARM_IP_TARGET", "value": "3"}
                ]
              }]
            }
          }
        }
      }'
    EOT
  }

  depends_on = [kubernetes_config_map.vpc_cni_config]
}
