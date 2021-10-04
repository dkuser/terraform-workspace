terraform {
  required_providers {
    gitlab = {
      source  = "gitlabhq/gitlab"
      version = "~> 3.6.0"
    }
  }
  required_version = ">= 0.15.3"
}

provider "gitlab" {
  token = var.access_token
}