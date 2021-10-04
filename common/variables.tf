variable "region" {
  description = "the AWS region in which resources are created, you must set the availability_zones variable as well if you define this value to something other than the default"
}
variable "project" {}
variable "application" {}
variable "containers" {}
variable "domain" {}
variable "groups" {}
variable "users" {}
variable "gitlab_access_token" {}
variable "gitlab_project" {}