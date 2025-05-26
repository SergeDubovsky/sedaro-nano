terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
  }
}

provider "github" {
  owner = var.github_owner
  # token can be set via GITHUB_TOKEN environment variable
}

data "terraform_remote_state" "bootstrap" {
  backend = "local"

  config = {
    path = "../terraform-bootstrap/terraform.tfstate"
  }
}