output "repository_urls" {
  description = "URLs of the created ECR repositories"
  value       = { for repo_name, repo in aws_ecr_repository.repositories : repo_name => repo.repository_url }
}

output "repository_arns" {
  description = "ARNs of the created ECR repositories"
  value       = { for repo_name, repo in aws_ecr_repository.repositories : repo_name => repo.arn }
}

output "registry_id" {
  description = "Registry ID of the ECR repositories"
  value       = aws_ecr_repository.repositories[local.repositories[0]].registry_id
}