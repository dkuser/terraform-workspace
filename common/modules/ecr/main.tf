locals {
  url = aws_ecr_repository.repo.repository_url
  name = aws_ecr_repository.repo.name
}


resource "aws_ecr_repository" "repo" {
  name = var.name
}

resource "aws_ecr_lifecycle_policy" "policy" {
  repository = aws_ecr_repository.repo.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "keep last images"
      action = {
        type = "expire"
      }
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = var.amount_to_keep
      }
    }]
  })
}