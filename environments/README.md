# Sedaro Nano - Modular Terraform Infrastructure

This repository has been refactored to use a modular Terraform structure with environment-specific configurations.

## Directory Structure

```
├── modules/                    # Reusable Terraform modules
│   ├── bootstrap/             # AWS infrastructure bootstrap (IAM, S3, DynamoDB)
│   ├── eks-cluster/           # EKS cluster and VPC infrastructure
│   ├── eks-addons/            # EKS add-ons (ALB Controller, Metrics Server, etc.)
│   └── github-secrets/        # GitHub Actions secrets management
├── environments/              # Environment-specific configurations
│   └── demo/                  # Demo environment
│       ├── main.tf           # Main configuration using modules
│       ├── variables.tf      # Environment variables
│       ├── outputs.tf        # Environment outputs
│       └── terraform.tfvars  # Environment-specific values
└── terraform*/               # Legacy directories (to be deprecated)
```

## Usage

### 1. Bootstrap (One-time setup)
```bash
cd modules/bootstrap
terraform init
terraform plan
terraform apply
```

### 2. Deploy Demo Environment
```bash
cd environments/demo

# Set required environment variables
export TF_VAR_github_actions_role_arn="arn:aws:iam::ACCOUNT:role/sedaro-nano-github-actions-role"
export TF_VAR_admin_user_arn="arn:aws:iam::ACCOUNT:user/YOUR_USER"

# Deploy infrastructure
terraform init
terraform plan
terraform apply
```

### 3. GitHub Secrets (Optional)
```bash
cd modules/github-secrets

# Set GitHub token
export GITHUB_TOKEN="your_github_token"

terraform init
terraform plan -var="github_actions_role_arn=arn:aws:iam::ACCOUNT:role/sedaro-nano-github-actions-role"
terraform apply
```

## Modules

### bootstrap
- Creates IAM OIDC provider for GitHub Actions
- Creates IAM role for GitHub Actions with EKS permissions
- Creates S3 bucket and DynamoDB table for Terraform state

### eks-cluster
- Creates VPC with public/private subnets
- Creates EKS cluster with managed node groups
- Creates IAM role for AWS Load Balancer Controller
- Configures cluster access for GitHub Actions and admin users

### eks-addons
- Deploys AWS Load Balancer Controller
- Optionally deploys Metrics Server
- Optionally deploys Cluster Autoscaler

### github-secrets
- Creates GitHub Actions secrets for AWS role ARN

## Environment Variables

Required for demo environment:
- `TF_VAR_github_actions_role_arn` - ARN of GitHub Actions IAM role
- `TF_VAR_admin_user_arn` - ARN of admin user/role (optional)

Optional for github-secrets:
- `GITHUB_TOKEN` - GitHub personal access token

## Adding New Environments

To add a new environment (e.g., staging):

1. Create directory: `environments/staging/`
2. Copy files from `environments/demo/`
3. Update `terraform.tfvars` with staging-specific values
4. Update backend configuration in `main.tf` to use staging state key

## Migration from Legacy Structure

The legacy `terraform/`, `terraform-addons/`, `terraform-bootstrap/`, and `terraform-github-secrets/` directories will be deprecated once the new modular structure is validated.

## Benefits of Modular Structure

1. **Reusability** - Modules can be used across multiple environments
2. **Maintainability** - Changes to modules automatically apply to all environments
3. **Scalability** - Easy to add new environments (staging, prod, etc.)
4. **Best Practices** - Follows Terraform module best practices
5. **Environment Isolation** - Each environment has its own state file
