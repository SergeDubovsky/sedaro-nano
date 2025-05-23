output "github_actions_role_arn" {
  description = "ARN of the IAM role for GitHub Actions"
  value       = aws_iam_role.github_actions.arn
}

output "terraform_state_bucket" {
  description = "Name of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.id
}

output "terraform_state_lock_table" {
  description = "Name of the DynamoDB table for Terraform state locking"
  value       = aws_dynamodb_table.terraform_state_lock.id
}

output "github_oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider"
  value       = aws_iam_openid_connect_provider.github.arn
}

output "github_actions_workflow_config" {
  description = "Configuration snippet for GitHub Actions workflow"
  value = <<-EOT
    # Add this to your GitHub Actions workflow file:
    
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
              role-to-assume: ${aws_iam_role.github_actions.arn}
              aws-region: ${var.aws_region}
  EOT
}
