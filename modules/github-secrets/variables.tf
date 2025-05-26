variable "github_owner" {
  type        = string
  description = "The GitHub organization or user that owns the repository."
}

variable "repository_name" {
  type        = string
  description = "The name of the GitHub repository."
}

variable "github_actions_role_arn" {
  description = "The ARN of the GitHub Actions IAM role"
  type        = string
}
