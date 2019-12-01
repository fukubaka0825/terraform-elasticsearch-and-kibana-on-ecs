resource "aws_ecs_service" "default" {
  name                              = var.service_name
  cluster                           = var.cluster_arn
  task_definition                   = var.task_definition
  iam_role                          = var.ecs_service_role_arn
  desired_count                     = var.desired_count
  launch_type                       = "EC2"
  health_check_grace_period_seconds = var.health_check_grace_period_seconds
  scheduling_strategy               = var.scheduling_strategy

  dynamic ordered_placement_strategy {
    for_each = var.has_ordered_placement_strategy ? { dummy = "hoge" } : {}
    content {
      type  = var.ordered_placement_strategy_type
      field = var.ordered_placement_strategy_field
    }
  }

  dynamic placement_constraints {
    for_each = var.has_placement_constraints ? { dummy = "hoge" } : {}
    content {
      type       = var.placement_constraints_type
      expression = var.placement_constraints_expression
    }
  }

  deployment_controller {
    type = var.deploy_type
  }

  dynamic load_balancer {
    //is_load_balancer_modeがfalseならこのargument設定されない
    for_each = var.has_load_balancer ? { dummy = "hoge" } : {}
    content {
      target_group_arn = var.target_group_arn
      container_name   = var.container_name
      container_port   = var.container_port
    }
  }

  lifecycle {
    ignore_changes = [task_definition, load_balancer]
  }
}

resource "aws_appautoscaling_target" "ecs_target" {
  count              = var.has_autoScaling ? 1 : 0
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.default.name}"
  role_arn           = var.ecs_scale_role
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  lifecycle {
    ignore_changes = [role_arn]
  }
}

# Automatically scale capacity up by one
resource "aws_appautoscaling_policy" "scale_out" {
  count              = var.has_autoScaling ? 1 : 0
  name               = "${var.service_name}-task_scale_up"
  service_namespace  = aws_appautoscaling_target.ecs_target[count.index].service_namespace
  resource_id        = aws_appautoscaling_target.ecs_target[count.index].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[count.index].scalable_dimension

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 300
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }

  depends_on = [aws_appautoscaling_target.ecs_target]
}

# Automatically scale capacity down by one
resource "aws_appautoscaling_policy" "scale_in" {
  count              = var.has_autoScaling ? 1 : 0
  name               = "${var.service_name}-task_scale_down"
  service_namespace  = aws_appautoscaling_target.ecs_target[count.index].service_namespace
  resource_id        = aws_appautoscaling_target.ecs_target[count.index].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[count.index].scalable_dimension

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 300
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }

  depends_on = [aws_appautoscaling_target.ecs_target]
}

