data "aws_iam_role" "service" {
  name = "ecsServiceRole"
}

resource "aws_ecs_service" "this" {
  for_each                           = { for i, s in var.services : i => s }
  name                               = each.value.name
  cluster                            = var.cluster_id
  task_definition                    = each.value.task_definition
  deployment_minimum_healthy_percent = try(each.value.deployment_minimum_healthy_percent, null)
  deployment_maximum_percent         = try(each.value.deployment_maximum_percent, null)
  desired_count                      = try(each.value.desired_count, 1)
  scheduling_strategy                = try(each.value.scheduling_strategy, "REPLICA")
  health_check_grace_period_seconds  = try(each.value.health_check_grace_period_seconds, null)
  iam_role                           = var.is_network_mode_awsvpc == true ? null : data.aws_iam_role.service.arn
  wait_for_steady_state              = try(each.value.wait_for_steady_state, true)
  force_new_deployment               = try(each.value.force_new_deployment, false)
  tags                               = var.tags
  launch_type                        = var.launch_type

  lifecycle {
    ignore_changes = [desired_count, task_definition]
  }

  dynamic "ordered_placement_strategy" {
    for_each = try(each.value.ordered_placement_strategies, [])

    content {
      field = ordered_placement_strategy.value.field
      type  = ordered_placement_strategy.value.type
    }
  }

  dynamic "load_balancer" {
    for_each = try(each.value.load_balancers, [])

    content {
      target_group_arn = load_balancer.value.target_group_arn
      container_name   = load_balancer.value.container_name
      container_port   = load_balancer.value.container_port
    }
  }

  dynamic "capacity_provider_strategy" {
    for_each = try(each.value.capacity_provider_strategies, [])

    content {
      capacity_provider = try(capacity_provider_strategy.value.capacity_provider, "FARGATE")
      base              = try(capacity_provider_strategy.value.base, 1)
      weight            = try(capacity_provider_strategy.value.weight, 1)
    }
  }

  dynamic "network_configuration" {
    for_each = try(each.value.network_configuration, null) != null ? [1] : []

    content {
      subnets          = var.subnets
      security_groups  = var.security_groups
      assign_public_ip = try(each.value.network_configuration.assign_public_ip, false)
    }
  }

  dynamic "deployment_circuit_breaker" {
    for_each = try(each.value.deployment_circuit_breakers, [])

    content {
      enable   = try(deployment_circuit_breaker.value.enable, false)
      rollback = try(deployment_circuit_breaker.value.rollback, false)
    }
  }

  dynamic "deployment_controller" {
    for_each = try(each.value.deployment_controllers, [])

    content {
      type = try(deployment_controller.value.type, "ECS")
    }
  }
}

resource "aws_appautoscaling_target" "this" {
  depends_on         = [aws_ecs_service.this]
  for_each           = { for i, s in var.services : i => s if try(s.enable_autoscaling, true) }
  min_capacity       = try(each.value.min_capacity, 1)
  max_capacity       = coalesce(try(each.value.max_capacity, null), try(each.value.min_capacity, 1))
  resource_id        = "service/${var.cluster_name}/${each.value.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "this" {
  for_each           = { for i, s in var.services : i => s if try(s.enable_autoscaling, true) }
  name               = "${var.cluster_name}-${each.value.name}"
  policy_type        = try(each.value.policy_type, "TargetTrackingScaling")
  resource_id        = aws_appautoscaling_target.this[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.this[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.this[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = try(each.value.target_value, 40)
    disable_scale_in   = try(each.value.disable_scale_in, false)
    scale_in_cooldown  = try(each.value.scale_in_cooldown, null)
    scale_out_cooldown = try(each.value.scale_out_cooldown, null)

    predefined_metric_specification {
      predefined_metric_type = try(each.value.predefined_metric_type, "ECSServiceAverageCPUUtilization")
    }
  }
}
