terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.10.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-2"
}

module "vpc" {
  source         = "git::https://github.com/inflearn/terraform-aws-vpc.git?ref=v3.14.0"
  name           = "example-inflab-ecs-service-complete-fargate"
  cidr           = "10.0.0.0/16"
  azs            = ["ap-northeast-2a", "ap-northeast-2c"]
  public_subnets = ["10.0.0.0/24", "10.0.1.0/24"]

  tags = {
    iac  = "terraform"
    temp = "true"
  }
}

module "security_group_ecs" {
  source      = "git::https://github.com/inflearn/terraform-aws-security-group.git?ref=v1.0.0-inflab"
  name        = "example-inflab-ecs-service-complete-fargate"
  description = "Security group terraform example elasticache"
  vpc_id      = module.vpc.vpc_id

  ingress_rules       = ["all-all"]
  ingress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules        = ["all-all"]
  egress_cidr_blocks  = ["0.0.0.0/0"]
}

module "ecs_cluster" {
  source                    = "git::https://github.com/inflearn/terraform-aws-ecs-cluster.git?ref=v1.0.0-inflab"
  name                      = "example-inflab-ecs-service-complete-fargate"
  type                      = "FARGATE"
  enable_container_insights = true

  tags = {
    iac  = "terraform"
    temp = "true"
  }
}

module "ecs_task_definition" {
  source       = "git::https://github.com/inflearn/terraform-aws-ecs-task-definition.git?ref=v1.0.0-inflab"
  cluster_name = "example-inflab-ecs-service-complete-fargate"
  region       = "ap-northeast-2"

  task_definitions = [
    {
      name                     = "task-definition"
      requires_compatibilities = ["FARGATE"]
      task_role_arn            = null
      network_mode             = "awsvpc"
      volumes                  = []
      cpu                      = 256
      memory                   = 512
      runtime_platform         = {
        operating_system_family = "LINUX"
        cpu_architecture        = "X86_64"
      }
      container_definitions = [
        {
          name               = "container"
          log_retention_days = 7
          image              = "ubuntu:latest"
          essential          = true
          dependsOn          = null
          portMappings       = null
          healthCheck        = null
          linuxParameters    = null
          environment        = null
          entryPoint         = null
          command            = null
          workingDirectory   = null
          secrets            = null
          mountPoints        = null
        }
      ]
    }
  ]

  tags = {
    iac  = "terraform"
    temp = "true"
  }
}

module "ecs_service" {
  source              = "../../"
  cluster_id          = module.ecs_cluster.cluster_id
  cluster_name        = "example-inflab-ecs-service-complete-fargate"
  task_definition_arn = module.ecs_task_definition.task_definitions[0]
  subnets             = module.vpc.public_subnets
  security_groups     = [module.security_group_ecs.security_group_id]
  region              = "ap-northeast-2"

  services = [
    {
      name                               = "service"
      deployment_minimum_healthy_percent = 100
      deployment_maximum_percent         = 200
      scheduling_strategy                = "REPLICA"
      health_check_grace_period_seconds  = null
      load_balancers                     = []
      wait_for_steady_state              = true
      force_new_deployment               = false
      ordered_placement_strategies       = []
      capacity_provider_strategies       = []
      network_configuration              = { assign_public_ip = true }
      deployment_circuit_breakers        = []
      deployment_controllers             = []
      enable_autoscaling                 = true
      min_capacity                       = 1
      max_capacity                       = 2
      policy_type                        = "TargetTrackingScaling"
      target_value                       = 40
      disable_scale_in                   = false
      scale_in_cooldown                  = 10
      scale_out_cooldown                 = 10
      predefined_metric_type             = "ECSServiceAverageCPUUtilization"
    }
  ]

  tags = {
    iac  = "terraform"
    temp = "true"
  }
}
