data "gitlab_project" "app" {
  id = var.project
}

resource "gitlab_project_variable" "variable" {
  for_each = var.variables

  project   = data.gitlab_project.app.id
  key       = each.key
  value     = each.value.value
  protected = each.value.protected
  masked    = each.value.masked
}