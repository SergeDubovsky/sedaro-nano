# Terraform Modular Structure

This project has been refactored from a monolithic Terraform structure to a modular, environment-based architecture. This approach provides better maintainability, reusability, and scalability for managing multiple environments.

## Directory Structure

```
├── terraform/                        # All Infrastructure as Code
│   ├── modules/                      # Reusable Terraform modules
│   │   ├── bootstrap/                # Bootstrap infrastructure (IAM, S3, DynamoDB)
│   │   ├── eks-addons/               # EKS add-ons (Load Balancer Controller, etc.)
│   │   ├── eks-cluster/              # Core EKS cluster infrastructure
│   │   └── github-secrets/           # GitHub Actions secrets management
│   ├── environments/                 # Environment-specific configurations
│   │   └── demo/                     # Demo environment configuration
│   └── legacy-archive/               # Archived legacy Terraform directories
│       ├── terraform/                # Legacy - main EKS infrastructure
│       ├── terraform-addons/         # Legacy - EKS add-ons
│       ├── terraform-bootstrap/      # Legacy - bootstrap infrastructure
│       └── terraform-github-secrets/ # Legacy - GitHub secrets
├── app/                              # Backend application code
├── web/                              # Frontend application code
├── queries/                          # Query parsing library
└── k8s/                              # Kubernetes manifests
```

## Modules Overview

### `modules/bootstrap/`
- **Purpose**: Sets up foundational AWS infrastructure
- **Resources**: IAM roles, OIDC provider, S3 backend bucket, DynamoDB lock table
- **Usage**: Required before deploying any other infrastructure

### `modules/eks-cluster/`
- **Purpose**: Creates the core EKS cluster and VPC infrastructure
- **Resources**: VPC, EKS cluster, IAM roles, Load Balancer Controller IRSA role
- **Dependencies**: Requires bootstrap module outputs

### `modules/eks-addons/`
- **Purpose**: Deploys optional EKS add-ons and controllers
- **Resources**: AWS Load Balancer Controller, Metrics Server (optional), Cluster Autoscaler (optional)
- **Dependencies**: Requires EKS cluster module outputs

### `modules/github-secrets/`
- **Purpose**: Manages GitHub Actions secrets for CI/CD
- **Resources**: GitHub repository secrets for AWS integration
- **Dependencies**: Requires AWS IAM role ARN

## Environment Configuration

### Demo Environment (`environments/demo/`)

The demo environment uses all modules to create a complete EKS infrastructure:

1. **Bootstrap** - Creates foundational AWS resources
2. **EKS Cluster** - Deploys the main EKS cluster with VPC
3. **EKS Add-ons** - Installs Load Balancer Controller and optional components
4. **GitHub Secrets** - Configures CI/CD secrets

### Configuration Files

- `main.tf` - Module instantiations and configuration
- `variables.tf` - Environment-specific variable definitions
- `outputs.tf` - Environment outputs
- `terraform.tfvars` - Environment-specific values

## Usage

### Prerequisites

1. AWS CLI configured with appropriate credentials
2. Terraform >= 1.12.1 installed
3. kubectl installed (for post-deployment tasks)

### Deploying the Demo Environment

```bash
# Navigate to the demo environment
cd terraform/environments/demo

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply
```

### Using GitHub Actions

The workflows have been updated to use the new modular structure:

- **Deploy**: Triggered on pushes to main branch affecting `terraform/environments/**` or `terraform/modules/**`
- **Destroy**: Manual workflow requiring confirmation

### Adding New Environments

To create a new environment (e.g., staging, production):

1. Create a new directory under `terraform/environments/`
2. Copy the demo environment files as a template
3. Modify `terraform.tfvars` with environment-specific values
4. Update variable values in `variables.tf` if needed
5. Customize module configurations in `main.tf` as required

Example for staging environment:

```bash
# Create staging environment
mkdir -p terraform/environments/staging
cp terraform/environments/demo/* terraform/environments/staging/

# Modify staging-specific values
edit terraform/environments/staging/terraform.tfvars
edit terraform/environments/staging/variables.tf
```

## Module Variables

### Common Variables Across Environments

- `region` - AWS region for deployment
- `environment` - Environment name (demo, staging, prod)
- `cluster_name` - EKS cluster name
- `github_repository` - GitHub repository name
- `admin_user_arn` - ARN of admin user for cluster access

### Optional Add-on Flags

- `enable_metrics_server` - Deploy Kubernetes Metrics Server
- `enable_cluster_autoscaler` - Deploy Cluster Autoscaler

## Migration from Legacy Structure

The legacy Terraform directories have been moved to `terraform/legacy-archive/` to preserve state files and configuration history. The archive contains:

- `terraform/legacy-archive/terraform/` - Original EKS infrastructure
- `terraform/legacy-archive/terraform-addons/` - Original EKS add-ons  
- `terraform/legacy-archive/terraform-bootstrap/` - Original bootstrap infrastructure
- `terraform/legacy-archive/terraform-github-secrets/` - Original GitHub secrets

**Important**: The archived directories contain active Terraform state files. If you need to manage existing resources deployed with the legacy configuration, use the archived directories until resources are migrated or destroyed.

### Key Changes Made

1. **Modularization**: Split monolithic configurations into reusable modules
2. **Environment Abstraction**: Environment-specific values separated from module logic
3. **Simplified Dependencies**: Removed remote state dependencies between modules
4. **Enhanced Flexibility**: Added enable/disable flags for optional components
5. **Updated Workflows**: GitHub Actions workflows updated for new structure
6. **Legacy Archive**: Moved old directories to `terraform-legacy-archive/` preserving state files

### Validation Steps

1. Verify module functionality in demo environment
2. Test GitHub Actions workflows
3. Validate resource creation and destruction
4. Confirm state management works correctly

## Best Practices

1. **Environment Isolation**: Each environment maintains its own state
2. **Module Reusability**: Modules are generic and configurable
3. **Version Control**: Pin module versions in production environments
4. **Testing**: Validate changes in demo before applying to production
5. **Documentation**: Keep module documentation up to date

## Troubleshooting

### Common Issues

1. **State Backend**: Ensure bootstrap module runs first to create S3 backend
2. **IAM Permissions**: Verify GitHub Actions role has necessary permissions
3. **VPC Limits**: Check AWS VPC limits if cluster creation fails
4. **Module Dependencies**: Ensure proper dependency order in environment configuration

### Getting Help

- Check module outputs for debugging information
- Review Terraform state for resource status
- Use `terraform refresh` to sync state with actual resources
- Check AWS CloudTrail for permission issues
