output "task_definition_arn" {
  value = aws_ecs_task_definition.default.arn
}
output "task_definition_family" {
  value = aws_ecs_task_definition.default.family
}