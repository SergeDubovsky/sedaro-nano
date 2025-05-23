# Terraform Add-ons (Stage 2)

This directory contains Terraform configuration for deploying Kubernetes add-ons to the EKS cluster created in Stage 1.

## Prerequisites

1. Stage 1 infrastructure must be deployed first (`../terraform/`)
2. EKS cluster must be running and accessible
3. AWS credentials configured

## What This Deploys

- **AWS Load Balancer Controller**: Manages AWS Load Balancers for Kubernetes services and ingresses
- Additional add-ons can be added as needed (metrics-server, cluster-autoscaler, etc.)

## Usage

### 1. Initialize Terraform
```bash
terraform init
```

### 2. Plan the deployment
```bash
terraform plan
```

### 3. Apply the configuration
```bash
terraform apply
```

## State Management

This configuration uses a separate S3 state file (`terraform-addons.tfstate`) and reads the infrastructure state from Stage 1 using `terraform_remote_state` data source.

## Dependencies

This configuration depends on outputs from the infrastructure stage:
- `cluster_name`
- `cluster_endpoint` 
- `cluster_certificate_authority_data`
- `aws_load_balancer_controller_role_arn`

## Notes

- The Helm and Kubernetes providers can authenticate successfully here because the EKS cluster already exists
- This solves the chicken-and-egg problem of provider authentication during initial cluster creation
