output "groups" {
  value = aws_iam_group.group
}

output "users" {
  value = aws_iam_user.user
}

output "access_keys" {
  value = aws_iam_access_key.access_key
}