resource "aws_cloudwatch_log_group" "log_group" {
  name = "${var.name}-${var.environment}"

  tags = {
    Environment = var.environment
    Application = var.name
  }
}