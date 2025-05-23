# GitHub OIDC Authentication for Terraform

This directory contains Terraform configuration for setting up GitHub Actions OIDC authentication with AWS. This allows GitHub Actions workflows to deploy infrastructure to AWS without storing long-lived credentials as GitHub secrets.

## What This Creates

1. **GitHub OIDC Provider**: Establishes the trust relationship between AWS and GitHub Actions
2. **IAM Role for GitHub Actions**: A role that the workflows can assume
3. **S3 Bucket for Terraform State**: For storing the Terraform state files securely
4. **DynamoDB Table for State Locking**: Prevents concurrent state modifications
5. **IAM Policies**: Granting necessary permissions to manage the project infrastructure

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0 installed
- Administrative access to the AWS account

## Setup Instructions

### 1. Update Variables

Edit `terraform.tfvars` to include your GitHub repository information:

```hcl
github_repo   = "your-github-org/your-repo-name"
github_branch = "main"  # Or the branch where your workflow runs
```

### 2. Initialize Terraform

```powershell
cd terraform-bootstrap
terraform init
```

### 3. Review Plan

```powershell
terraform plan
```

### 4. Apply Configuration

```powershell
terraform apply
```

### 5. Note the Outputs

After successful application, Terraform will output:
- GitHub Actions role ARN
- S3 bucket name for Terraform state
- DynamoDB table name for state locking
- A sample snippet for your GitHub Actions workflow

## Integrating with GitHub Actions

Add the following to your GitHub Actions workflow file:

```yaml
permissions:
  id-token: write # Required for OIDC authentication
  contents: read

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          role-to-assume: <github_actions_role_arn from output>
          aws-region: us-east-1
```

Then update your main Terraform configuration to use the S3 backend:

```hcl
terraform {
  backend "s3" {
    bucket         = "<terraform_state_bucket from output>"
    key            = "demo/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "<terraform_state_lock_table from output>"
  }
}
```

## Security Considerations

- This setup limits GitHub Actions workflows to only access AWS when they run on the specified repository and branch.
- The IAM policies create in this bootstrap process should be reviewed and possibly scoped down further for production use.
- The S3 bucket for Terraform state is configured with versioning and encryption to protect sensitive information.

## Cleanup

To remove all resources created by this configuration:

```powershell
terraform destroy
```

Note: If you've already stored state in the S3 bucket, you'll need to empty it first before Terraform can destroy it.
