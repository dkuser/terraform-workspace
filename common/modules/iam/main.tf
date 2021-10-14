resource "aws_iam_group" "group" {
  for_each = var.groups
  name     = each.key
}

resource "aws_iam_group_policy" "group_policy" {
  for_each = var.groups
  name     = "${each.key}_group_policy"
  group    = aws_iam_group.group[each.key].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = each.value
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_user" "user" {
  for_each = var.users
  name     = each.value.name
}

resource "aws_iam_group_membership" "member" {
  for_each = var.users
  name     = "${each.value.name}-${each.value.group}-membership"

  users = [
    aws_iam_user.user[each.value.name].name,
  ]

  group = aws_iam_group.group[each.value.group].name
}

resource "aws_iam_access_key" "access_key" {
  for_each = { for k in compact([for k, v in var.users : v.key ? k : ""]) : k => var.users[k] }

  user = aws_iam_user.user[each.value.name].name
}

resource "local_file" "aws_creds" {
  for_each = aws_iam_access_key.access_key
  content  = templatefile("${path.module}/credentials.tpl", { aws_access_key_id = each.value.id, aws_secret_access_key = each.value.secret })
  filename = "${path.module}/../../users/${each.value.user}_credentials"
}