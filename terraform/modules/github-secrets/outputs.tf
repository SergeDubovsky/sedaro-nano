output "aws_role_secret_created" {
  description = "Indicates that the AWS role ARN secret has been created"
  value       = github_actions_secret.aws_role_arn.secret_name
}
