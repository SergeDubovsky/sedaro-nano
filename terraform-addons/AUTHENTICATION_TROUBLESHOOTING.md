# Alternative Provider Configuration for GitHub Actions

This file documents an alternative approach to Kubernetes/Helm provider authentication that may work better in GitHub Actions environments.

## Option 1: Token-based Authentication (Current)

The current configuration uses the AWS EKS get-token command via exec provider:

```hcl
provider "kubernetes" {
  host                   = data.terraform_remote_state.infrastructure.outputs.cluster_endpoint
  cluster_ca_certificate = base64decode(data.terraform_remote_state.infrastructure.outputs.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks", "get-token",
      "--cluster-name", data.terraform_remote_state.infrastructure.outputs.cluster_name,
      "--region", var.aws_region,
      "--output", "json"
    ]
    env = {
      AWS_REGION = var.aws_region
    }
  }
}
```

## Option 2: Config File Authentication

If the exec provider continues to fail, we can try using the config_path approach:

```hcl
provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}
```

## Option 3: Environment Variables

Set KUBECONFIG environment variable in GitHub Actions:

```yaml
env:
  KUBECONFIG: ~/.kube/config
  AWS_REGION: ${{ vars.AWS_REGION || 'us-east-1' }}
```

## Troubleshooting Steps

1. Verify AWS CLI is properly configured and can access EKS
2. Ensure kubectl can connect to the cluster before Terraform runs
3. Test the aws eks get-token command manually
4. Check if KUBECONFIG environment variable is set correctly
5. Verify the cluster endpoint and certificate are accessible

## Implementation Notes

The GitHub Actions workflow now includes:
- Explicit kubectl installation and configuration
- Pre-flight checks to verify cluster connectivity
- Environment variables for AWS region and kubeconfig path
- Testing of the aws eks get-token command before Terraform execution
