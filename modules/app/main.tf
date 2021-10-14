locals {
  app_name = "web"
}

module "cluster" {
  source      = "../ecs_cluster"
  name        = var.project
  environment = var.environment
}

module "roles" {
  source      = "../ecs_roles"
  environment = var.environment
  secrets_arn = module.secrets.arn
}

module "logs" {
  source                 = "../cloudwatch"
  environment            = var.environment
  name                   = var.project
  logs_retention_in_days = 30
}

module "task_definition" {
  source                   = "../ecs_task_definition"
  environment              = var.environment
  name                     = "${var.project}-${var.application}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = module.roles.execution_role_arn
  task_role_arn            = module.roles.task_role_arn
  container_definitions = [
    {
      name      = var.containers.web.name
      image     = var.image
      essential = true
      links     = []

      volumesFrom = []
      mountPoints = []
      links       = []
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = module.logs.name
          awslogs-region        = var.region
          awslogs-stream-prefix = var.containers.web.name
        }
      }
      linuxParameters = {
        initProcessEnabled = true
      }
      environment = module.variables.map
      secrets     = module.secrets.map
    }
  ]
}


data "aws_acm_certificate" "cert" {
  domain   = var.domain
  statuses = ["ISSUED"]
}

module "alb" {
  source            = "../alb"
  name              = var.project
  environment       = var.environment
  security_groups   = var.alb_sg
  subnets           = var.public_subnets
  vpc_id            = var.vpc_id
  health_check_path = "/health_check"
  certificate_arn   = data.aws_acm_certificate.cert.arn
}

module "service" {
  source                   = "../ecs_service"
  name                     = var.project
  environment              = var.environment
  cluster_id               = module.cluster.id
  task_definition_arn      = module.task_definition.arn
  desired_count            = 2
  min_percent              = 50
  max_percent              = 300
  launch_type              = "FARGATE"
  scheduling_strategy      = "REPLICA"
  security_groups          = var.ecs_sg
  subnets                  = var.private_subnets
  aws_alb_target_group_arn = module.alb.tg_arn
  container_port           = var.container_port
  container_name           = var.containers.web.name
  enable_execute_command   = true
}

module "variables" {
  source = "../variables"
  map    = var.variables
}

module "secrets" {
  source      = "../secrets"
  name        = var.project
  environment = var.environment
  secrets     = var.secrets
}

module "autoscaling" {
  source                = "../autoscaling"
  cluster_name          = module.cluster.name
  service_name          = module.service.name
  cpu_average_target    = 60
  memory_average_target = 60
  scale_in_cooldown     = 300
  scale_out_cooldown    = 150
  max_capacity          = 4
  min_capacity          = 1
}

module "dashboard" {
  source           = "../dashboard"
  name             = var.project
  environment      = var.environment
  region           = var.region
  target_group_arn = module.alb.tg_arn_suffix
  alb_arn          = module.alb.alb_arn_suffix
  cluster_name     = module.cluster.name
  service_name     = module.service.name
}

module "dns" {
  source       = "../dns"
  domain       = var.domain
  alb_dns_name = module.alb.alb_dns_name
  alb_zone_id  = module.alb.alb_zone_id
  environment  = var.environment
}
