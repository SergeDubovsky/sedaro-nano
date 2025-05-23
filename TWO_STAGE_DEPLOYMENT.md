# Two-Stage Deployment Guide

This project now uses a **two-stage deployment approach** to solve the Kubernetes provider authentication issues in GitHub Actions.

## Architecture Overview

### Stage 1: Infrastructure (`terraform/`)
- **Purpose**: Deploy core AWS infrastructure
- **Includes**: VPC, EKS cluster, IAM roles
- **State**: `terraform.tfstate`
- **Providers**: AWS only

### Stage 2: Add-ons (`terraform-addons/`)
- **Purpose**: Deploy Kubernetes add-ons and controllers
- **Includes**: AWS Load Balancer Controller, other Helm charts
- **State**: `terraform-addons.tfstate`
- **Providers**: AWS, Kubernetes, Helm
- **Dependencies**: Reads Stage 1 state via `terraform_remote_state`

## Why Two Stages?

The two-stage approach solves the **chicken-and-egg problem** where:
1. Helm/Kubernetes providers need to authenticate to EKS cluster
2. But the EKS cluster is being created in the same Terraform run
3. Provider initialization happens before resource creation
4. This causes authentication failures in GitHub Actions

## Deployment Order

### Manual Deployment
```bash
# Stage 1: Deploy infrastructure
cd terraform/
terraform init
terraform plan
terraform apply

# Stage 2: Deploy add-ons (after Stage 1 completes)
cd ../terraform-addons/
terraform init
terraform plan
terraform apply

# Stage 3: Deploy workloads (optional)
kubectl apply -f k8s/
```

### GitHub Actions Deployment
The workflow `terraform-infra-two-stage.yml` handles this automatically:

1. **Validate** - Validates both Stage 1 and Stage 2 configurations
2. **Deploy Infrastructure** - Deploys Stage 1 (EKS cluster)
3. **Deploy Add-ons** - Deploys Stage 2 (Helm charts) 
4. **Deploy Workloads** - Deploys application manifests

## State Management

- **Stage 1 State**: `s3://sedaro-nano-terraform-state/demo/terraform.tfstate`
- **Stage 2 State**: `s3://sedaro-nano-terraform-state/demo/terraform-addons.tfstate`

Stage 2 reads Stage 1 outputs using:
```hcl
data "terraform_remote_state" "infrastructure" {
  backend = "s3"
  config = {
    bucket = "sedaro-nano-terraform-state"
    key    = "demo/terraform.tfstate"
    region = "us-east-1"
  }
}
```

## Benefits

1. **Solves Authentication Issues**: Providers only authenticate when target resources exist
2. **Separation of Concerns**: Infrastructure vs. Add-ons are managed separately
3. **Easier Debugging**: Issues can be isolated to specific stages
4. **Flexible Updates**: Can update add-ons without touching infrastructure
5. **Better CI/CD**: Each stage has clear success/failure points

## Migration from Single-Stage

If you have existing infrastructure, you'll need to:
1. Remove Helm resources from existing state
2. Import them into the new add-ons configuration
3. Update workflows to use two-stage approach

## Next Steps

1. Test the two-stage deployment locally
2. Update GitHub Actions workflows 
3. Test the full CI/CD pipeline
4. Add additional Helm charts to Stage 2 as needed
