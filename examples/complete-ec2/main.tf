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
  name           = "example-inflab-ecs-service-complete-ec2"
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
  name        = "example-inflab-ecs-service-complete-ec2"
  description = "Security group terraform example elasticache"
  vpc_id      = module.vpc.vpc_id

  ingress_rules       = ["all-all"]
  ingress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules        = ["all-all"]
  egress_cidr_blocks  = ["0.0.0.0/0"]
}

module "ecs_cluster" {
  source                      = "git::https://github.com/inflearn/terraform-aws-ecs-cluster.git?ref=v1.0.0-inflab"
  name                        = "example-inflab-ecs-service-complete-ec2"
  type                        = "EC2"
  subnets                     = module.vpc.public_subnets
  security_groups             = [module.security_group_ecs.security_group_id]
  public_key                  = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDaWw6IYEYDXaekkc6BzKMg1QeP9f4yyGee3c6OJPeSw9zZ6c7PE1V5hAjqxJwbIpO7LIEruB+LSFfWi5Q5l6QmTq0mt4gIQFfJfcQiTFjdM6Ig8Abwj6E3WQDOOivFY6HlFUDi7WyvGFHU+65R1e+a8qbBtQq2gZk2eI+V1FwT0mLmPe8JHhsKHDYKPsIpQRj96RSWLLJCxCeGAWOQz+0JnYtKhB/S3I2NsNBuRQlS8EZiIkXxbOicUb/NauqwqAyenk2TFyAj5+KhpIc2KZZcDeiWR3PdiEZEfwIR7BZwcpyFjOB9q5xDYmPf+lgDQ8/a4cAf02QqozDGbnxFa0Avw8DFpi5Ren7a4l+xG+Vh1OOCX1bAZniBwP6K6O6+hz910elOniRGv/pUfPCnVP+zv5ems7LQORi+Loaw23QLHGhKucVsi00IYm/JUxo6RXxBVvSkVOFHOnjJkyn4sSEr3u6vsptMlYSp7DQVg263rqX7U4nmVi1mjfc8IeA0WdE="
  ami                         = "ami-0ddef7b72b2854433"
  instance_type               = "t3a.micro"
  min_size                    = 1
  max_size                    = 1
  target_capacity             = 90
  capacity_provider_base      = 3
  capacity_provider_weight    = 100
  associate_public_ip_address = true
  enable_container_insights   = true

  tags = {
    iac  = "terraform"
    temp = "true"
  }
}

module "ecs_task_definition" {
  source       = "git::https://github.com/inflearn/terraform-aws-ecs-task-definition.git?ref=v1.0.0-inflab"
  cluster_name = "example-inflab-ecs-service-complete-ec2"
  region       = "ap-northeast-2"

  task_definitions = [
    {
      name                     = "task-definition"
      requires_compatibilities = ["EC2"]
      task_role_arn            = null
      network_mode             = "bridge"
      volumes                  = []
      container_definitions    = [
        {
          name               = "container"
          log_retention_days = 7
          image              = "ubuntu:latest"
          cpu                = 1024
          memoryReservation  = 1024
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
  cluster_name        = "example-inflab-ecs-service-complete-ec2"
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
      health_check_grace_period_seconds  = 30
      load_balancers                     = []
      wait_for_steady_state              = true
      force_new_deployment               = false
      ordered_placement_strategies       = []
      capacity_provider_strategies       = []
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
