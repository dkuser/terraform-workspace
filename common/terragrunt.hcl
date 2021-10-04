locals {
  workspace = run_cmd("--terragrunt-quiet", "terraform", "workspace", "show")
  region = "us-east-1"
  project = "infra-study"
  application = "app"
  containers = {
    web = {
      name = "web"
    }
  }
  domain = "studyinfra.onlinenumerator.com"
  bucket = "${local.project}-tfdima"
}

inputs = {
  region = local.region
  project = local.project
  application = local.application
  //containers = local.containers
  domain = local.domain
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket = local.bucket

    key = "terraform.tfstate"
    region         = local.region
    encrypt        = true
    dynamodb_table = "${local.project}-lock"
  }
}

terraform {
  extra_arguments "conditional_vars" {
    commands = [
      "apply",
      "init",
      "plan",
      "push",
      "refresh"
    ]

    required_var_files = [
      "../tfvars/terraform.tfvars"
    ]
  }

  after_hook "upload_vars" {
    commands     = ["apply"]
    execute      = ["make", "push_vars", "-f", "../Makefile"]
    run_on_error = false
  }
}