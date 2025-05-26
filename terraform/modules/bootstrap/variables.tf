variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "sedaro-nano"
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "github_repo" {
  description = "GitHub repository name (format: organization/repo)"
  type        = string
  default     = "sergedubovsky/sedaro-nano"
}

variable "github_branch" {
  description = "GitHub branch that's allowed to assume the role"
  type        = string
  default     = "main"
}
