output "arn" {
  value = "${local.family}:${local.revision}"
}