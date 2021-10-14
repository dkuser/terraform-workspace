resource "aws_cloudwatch_log_group" "log_group" {
  name              = "${var.name}-${var.environment}"
  retention_in_days = var.logs_retention_in_days

  tags = {
    Environment = var.environment
    Application = var.name
  }
}