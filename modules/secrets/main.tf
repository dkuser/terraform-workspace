resource "aws_kms_key" "encryption_key" {
  description             = "This key is used to encrypt SSM '${var.ssm_key_prefix}' parameters"
  deletion_window_in_days = 10
}

resource "aws_ssm_parameter" "secret_var" {
  for_each = var.secrets

  name      = "/${var.ssm_key_prefix}/${each.key}"
  type      = "SecureString"
  overwrite = true
  key_id    = aws_kms_key.encryption_key.arn
  value     = each.value
}

locals {
  arns    = values(aws_ssm_parameter.secret_var)[*].arn
  secrets = zipmap(keys(var.secrets), local.arns)

  secretMap = [for secretKey in keys(var.secrets) : {
    name      = secretKey
    valueFrom = lookup(local.secrets, secretKey)
    }
  ]
}