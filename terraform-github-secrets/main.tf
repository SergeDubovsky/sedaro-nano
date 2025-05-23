resource "github_actions_secret" "aws_role_arn" {
  repository      = var.repository_name
  secret_name     = "AWS_ROLE_ARN"
  plaintext_value = data.terraform_remote_state.bootstrap.outputs.aws_iam_role_arn
}
