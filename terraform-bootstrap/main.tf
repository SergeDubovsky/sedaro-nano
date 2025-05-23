locals {
  # Extract organization and repo name
  github_org  = split("/", var.github_repo)[0]
  github_repo = split("/", var.github_repo)[1]
  
  # Role name for GitHub Actions
  github_actions_role_name = "${var.project_name}-github-actions-role"
  
  # State resources
  state_bucket_name      = "${var.project_name}-terraform-state"
  state_lock_table_name  = "${var.project_name}-terraform-state-lock"
}

# OIDC Provider for GitHub
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["D1EB23A46D17D68FD92564C2F1F1601764D8E349"]
  
  tags = {
    Name = "GitHub-OIDC-Provider"
  }
}

# IAM Role for GitHub Actions
resource "aws_iam_role" "github_actions" {
  name = local.github_actions_role_name
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          },
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:ref:refs/heads/${var.github_branch}"
          }
        }
      }
    ]
  })
  
  description = "Role for GitHub Actions to deploy Terraform infrastructure for ${var.project_name}"
}

# Create S3 bucket for Terraform state
resource "aws_s3_bucket" "terraform_state" {
  bucket = local.state_bucket_name
  
  # Prevent accidental deletion
  lifecycle {
    prevent_destroy = true
  }
}

# Enable versioning on state bucket
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption on state bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access to the state bucket
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Create DynamoDB table for state locking
resource "aws_dynamodb_table" "terraform_state_lock" {
  name         = local.state_lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  
  attribute {
    name = "LockID"
    type = "S"
  }
}

# Policy for GitHub Actions to access Terraform state
resource "aws_iam_policy" "terraform_state_access" {
  name        = "${var.project_name}-terraform-state-access"
  description = "Policy granting access to Terraform state bucket and lock table"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        Resource = [
          aws_s3_bucket.terraform_state.arn,
          "${aws_s3_bucket.terraform_state.arn}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ],
        Resource = aws_dynamodb_table.terraform_state_lock.arn
      }
    ]
  })
}

# Policy for GitHub Actions to create and manage EKS cluster and related resources
resource "aws_iam_policy" "eks_management" {
  name        = "${var.project_name}-eks-management"
  description = "Policy granting permissions to create and manage EKS clusters for ${var.project_name}"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "eks:*",
          "ec2:*",
          "iam:*", 
          "elasticloadbalancing:*",
          "autoscaling:*"
        ],
        Resource = "*"
      }
    ]
  })
}

# Attach policies to the GitHub Actions role
resource "aws_iam_role_policy_attachment" "terraform_state_access" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.terraform_state_access.arn
}

resource "aws_iam_role_policy_attachment" "eks_management" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.eks_management.arn
}
