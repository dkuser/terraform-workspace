module "terraform_state_backend" {
  source = "cloudposse/tfstate-backend/aws"
  version     = "0.33.0"
  namespace   = var.namespace
  name        = var.name
  attributes  = var.attributes

  terraform_backend_config_file_path = var.config_path
  terraform_backend_config_file_name = var.config_name
  force_destroy                      = var.force_destroy
}

resource "local_file" "config" {
  content         = module.terraform_state_backend.terraform_backend_config
  filename        = "${var.copy_config_to}/${var.config_name}"
}