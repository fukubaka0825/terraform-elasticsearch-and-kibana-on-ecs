/* required */
variable "service_name" {}
variable "cluster_arn" {}
variable "task_definition" {}
variable "desired_count" {}
/* load_balancer argumentを設定したいなら　requierd */
variable "has_load_balancer" {
  description = "もしload_balancer argumentを設定したいなら、trueを入れる"
  default     = false
}
variable "ecs_scale_role" {
  default = null
}
/* load_balancer argumentを設定したら requierd　*/
variable "target_group_arn" {
  default = null
}
variable "container_name" {
  default = null
}
variable "health_check_grace_period_seconds" {
  default = null
}
variable "container_port" {
  default = 80
}

variable "has_autoScaling" {
  description = "もしautoScalingを設定したいなら、trueを入れる"
  default     = false
}
/* if has_autoScaling=ture requierd　*/
variable "max_capacity" {
  default = null
}
variable "min_capacity" {
  default = null
}
variable "cluster_name" {
  default = null
}


/* optional */
variable "ecs_service_role_arn" {
  default = null
}
variable "role_arn" {
  default = null
}

variable "deploy_type" {
  default = "ECS"
}

variable "scheduling_strategy" {
  default = "REPLICA"
}

variable "ordered_placement_strategy_type" {
  default = "spread"
}

variable "ordered_placement_strategy_field" {
  default = "instanceId"
}

variable "placement_constraints_type" {
  default = "memberOf"
}

variable "placement_constraints_expression" {
  default = "runningTasksCount <= 1"
}

variable "has_ordered_placement_strategy" {
  default = false
}

variable "has_placement_constraints" {
  default = false
}