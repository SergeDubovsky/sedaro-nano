locals {
  repositories = ["backend", "frontend"]

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_ecr_repository" "repositories" {
  for_each = toset(local.repositories)

  name                 = "${var.project_name}-${var.environment}-${each.value}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(local.common_tags, {
    Repository = each.value
  })
}

resource "aws_ecr_lifecycle_policy" "repositories" {
  for_each = aws_ecr_repository.repositories

  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Delete untagged images older than 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

resource "aws_ecr_repository_policy" "repositories" {
  for_each = aws_ecr_repository.repositories

  repository = each.value.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowGitHubActionsPull"
        Effect = "Allow"
        Principal = {
          AWS = var.github_actions_role_arn
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
      },
      {
        Sid    = "AllowGitHubActionsPush"
        Effect = "Allow"
        Principal = {
          AWS = var.github_actions_role_arn
        }
        Action = [
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
      }
    ]
  })
}

resource "aws_ecr_repository" "helm_chart_repository" {
  name                 = var.helm_chart_repository_name # "${var.project_name}-${var.environment}-helm-charts" # Alternative naming
  image_tag_mutability = "MUTABLE"                      # Or "IMMUTABLE" if you prefer, OCI charts are versioned anyway

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  # Enable OCI artifact support - this is implicitly supported by ECR for new repos
  # but you can add a policy if strict OCI-only access is needed.

  tags = merge(local.common_tags, {
    RepositoryType = "helm-charts"
  })
}

resource "aws_ecr_lifecycle_policy" "helm_chart_repository" {
  repository = aws_ecr_repository.helm_chart_repository.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 20 chart versions",
        selection = {
          tagStatus   = "any", # Helm charts use tags for versions
          countType   = "imageCountMoreThan",
          countNumber = 20
        },
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# Policy to allow GitHub Actions to push/pull Helm charts
resource "aws_ecr_repository_policy" "helm_chart_repository" {
  repository = aws_ecr_repository.helm_chart_repository.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowHelmChartAccess",
        Effect = "Allow",
        Principal = {
          AWS = var.github_actions_role_arn
        },
        Action = [
          # Permissions needed for `helm push` and `helm pull` via OCI
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:GetDownloadUrlForLayer",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage", # Helm charts are stored as images in OCI
          "ecr:UploadLayerPart",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:BatchGetImage",
          "ecr:GetLifecyclePolicy",
          "ecr:GetLifecyclePolicyPreview",
          "ecr:ListTagsForResource",
          "ecr:DescribeImages"
        ]
      }
    ]
  })
}