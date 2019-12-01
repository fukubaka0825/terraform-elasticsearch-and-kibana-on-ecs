output "ecs_service_name" {
  value = aws_ecs_service.default.name
}

output "aws_appautoscaling_scale_in_policy_arn" {
  value = aws_appautoscaling_policy.scale_in[0].arn
}

output "aws_appautoscaling_scale_out_policy_arn" {
  value = aws_appautoscaling_policy.scale_out[0].arn
}
