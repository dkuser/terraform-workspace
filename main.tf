locals {
  variables = {
    PORT = var.container_port
  }
  containers = jsondecode(var.containers)
  openvpn_users = []
}

module "network" {
  source             = "./modules/network"
  cidr               = var.cidr
  private_subnets    = var.private_subnets
  public_subnets     = var.public_subnets
  availability_zones = var.availability_zones
}

module "security_groups" {
  source         = "./modules/security_groups"
  name           = "${var.project}-${var.environment}"
  vpc_id         = module.network.vpc_id
  container_port = var.container_port
}

module "app" {
  source          = "./modules/app"
  project         = var.project
  application     = var.application
  containers      = local.containers
  environment     = var.environment
  task_cpu        = var.task_cpu
  task_memory     = var.task_memory
  image           = var.image
  container_port  = var.container_port
  vpc_id          = module.network.vpc_id
  public_subnets  = module.network.public_subnets
  ecs_sg          = [module.security_groups.ecs_tasks]
  alb_sg          = [module.security_groups.alb]
  private_subnets = module.network.private_subnets
  region          = var.region
  variables       = local.variables
  secrets         = var.secrets
  domain          = var.domain
}

module "vpn" {
  source          = "./modules/vpn"
  domain = var.domain
  vpn_domain = "vpn.${var.environment}.${var.domain}"
  subnet_id = module.network.public_subnets[0].id
  security_groups = module.security_groups
  users = local.openvpn_users
  ovpn_config_directory = "generated/vpn/${var.environment}"
  vpn_pem_file = "generated/ssh_keys/vpn.pem"
  instance_type = "t3.micro"
  openvpn_install_script_location = "https://raw.githubusercontent.com/angristan/openvpn-install/master/openvpn-install.sh"
}