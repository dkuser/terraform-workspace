terraform {
  required_version = ">= 0.12.2"

  backend "s3" {
    region         = "us-east-1"
    bucket         = "studyaws-tf-state"
    key            = "terraform.tfstate"
    dynamodb_table = "studyaws-tf-state-lock"
    profile        = ""
    role_arn       = ""
    encrypt        = "true"
  }
}
