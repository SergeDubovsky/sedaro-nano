resource "github_actions_secret" "aws_role_arn" {
  repository      = var.repository_name
  secret_name     = "AWS_ROLE_ARN"
  plaintext_value = var.github_actions_role_arn
}
