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