locals {
  app_name = "web"
}

module "cluster" {
  source                      = "../ecs_cluster"
  name                        = local.app_name
  environment                 = var.environment
}

module "roles" {
  source                      = "../ecs_roles"
  environment                 = var.environment
}

module "task_definition" {
  source                      = "../ecs_task_definition"
  environment                 = var.environment
  name                        = var.name
  network_mode                = "awsvpc"
  requires_compatibilities    = ["FARGATE"]
  cpu                         = var.task_cpu
  memory                      = var.task_memory
  execution_role_arn          = module.roles.execution_role_arn
  task_role_arn               = module.roles.task_role_arn
  container_definitions       = [
    {
      name      = local.app_name
      image     = var.image
      essential = true
      links = []

      volumesFrom = []
      mountPoints = []
      links = []
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
        }
      ]
    }
  ]
}
