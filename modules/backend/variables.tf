variable "config_path" {
  description = "path where config will be located"
}

variable "config_name" {
  description = "name of the config"
}

variable "namespace" {
  description = "namespace"
}

variable "name" {
  description = "name"
  default = "tf"
}

variable "force_destroy" {
  description = "module force_destroy"
  default = false
}

variable "attributes" {
  description = "module attributes"
  default = ["state"]
}

variable "copy_config_to" {
  description = "directory where config should be copied  (to use the same backend in two directories)"
}