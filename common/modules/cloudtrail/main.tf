# The AWS region currently being used.
data "aws_region" "current" {}

# The AWS account id
data "aws_caller_identity" "current" {}

# The AWS partition (commercial or govcloud)
data "aws_partition" "current" {}

# This policy allows the CloudTrail service for any account to assume this role.
data "aws_iam_policy_document" "cloudtrail_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }
}

# This role is used by CloudTrail to send logs to CloudWatch.
resource "aws_iam_role" "cloudtrail_cloudwatch_role" {
  name               = "cloudtrail-cloudwatch-logs-role"
  assume_role_policy = data.aws_iam_policy_document.cloudtrail_assume_role.json
}

# This CloudWatch Group is used for storing CloudTrail logs.
resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "cloudtrail-events"
  retention_in_days = 0
}

data "aws_iam_policy_document" "cloudtrail_cloudwatch_policy_document" {
  statement {
    sid = "WriteCloudWatchLogs"

    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${aws_cloudwatch_log_group.cloudtrail.name}:log-stream:*"]
  }
}

resource "aws_iam_policy" "cloudtrail_cloudwatch_policy" {
  name   = "cloudtrail-cloudwatch-logs-policy"
  policy = data.aws_iam_policy_document.cloudtrail_cloudwatch_policy_document.json
}

resource "aws_iam_policy_attachment" "cloudtrail_cloudwatch_attachment" {
  name       = "cloudtrail-cloudwatch-logs-policy-attachment"
  policy_arn = aws_iam_policy.cloudtrail_cloudwatch_policy.arn
  roles      = [aws_iam_role.cloudtrail_cloudwatch_role.name]
}

resource "aws_s3_bucket" "cloudtrail" {
  bucket = "${var.prefix}-cloudtrail-bucket"
  acl    = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail_public_access_block" {
  bucket = aws_s3_bucket.cloudtrail.id

  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}

data "aws_iam_policy_document" "cloudtrail_s3_policy_document" {
  statement {
    sid = "AWSCloudTrailAclCheck"

    effect  = "Allow"
    actions = ["s3:GetBucketAcl"]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    resources = ["arn:aws:s3:::${aws_s3_bucket.cloudtrail.id}"]
  }

  statement {
    sid = "AWSCloudTrailWrite"

    effect  = "Allow"
    actions = ["s3:PutObject"]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      values   = ["bucket-owner-full-control"]
      variable = "s3:x-amz-acl"
    }

    resources = ["arn:aws:s3:::${aws_s3_bucket.cloudtrail.id}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]
  }
}

resource "aws_s3_bucket_policy" "cloudtrail_s3_policy" {
  bucket     = aws_s3_bucket.cloudtrail.id
  depends_on = [aws_s3_bucket.cloudtrail]
  policy     = data.aws_iam_policy_document.cloudtrail_s3_policy_document.json
}

resource "aws_cloudtrail" "cloudtrail" {
  depends_on = [aws_s3_bucket_policy.cloudtrail_s3_policy, aws_s3_bucket.cloudtrail]

  name                       = "events"
  enable_logging             = true
  is_multi_region_trail      = true
  enable_log_file_validation = true

  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_cloudwatch_role.arn

  s3_bucket_name = aws_s3_bucket.cloudtrail.id
}