output "cluster_id" {
  description = "The ID of the created ECS cluster."
  value       = "${element(concat(aws_ecs_cluster.cluster.*.id, list("")), 0)}"
}

output "cluster_name" {
  description = "The name of the created ECS cluster."
  value       = "${element(concat(aws_ecs_cluster.cluster.*.name, list("")), 0)}"
}

output "cluster_arn" {
  description = "The ARN of the created ECS cluster."
  value       = "${element(concat(aws_ecs_cluster.cluster.*.arn, list("")), 0)}"
}

output "security_group_id" {
  description = "The ID of the default security group associated with the ECS container instances."
  value       = "${element(concat(aws_security_group.cluster.*.id, list("")), 0)}"
}

output "instance_role_arn" {
  description = "The ARN of the container instance role."
  value       = "${element(concat(aws_iam_role.cluster_instance_role.*.arn, list("")), 0)}"
}

output "instance_role_id" {
  description = "The ID of the container instance role."
  value       = "${element(concat(aws_iam_role.cluster_instance_role.*.unique_id, list("")), 0)}"
}

output "instance_policy_arn" {
  description = "The ARN of the container instance policy."
  value       = "${element(concat(aws_iam_policy.cluster_instance_policy.*.arn, list("")), 0)}"
}

output "instance_policy_id" {
  description = "The ID of the container instance policy."
  value       = "${element(concat(aws_iam_policy.cluster_instance_policy.*.id, list("")), 0)}"
}

output "service_role_arn" {
  description = "The ARN of the ECS service role."
  value       = "${element(concat(aws_iam_role.cluster_service_role.*.arn, list("")), 0)}"
}

output "service_role_id" {
  description = "The ID of the ECS service role."
  value       = "${element(concat(aws_iam_role.cluster_service_role.*.unique_id, list("")), 0)}"
}

output "service_policy_arn" {
  description = "The ARN of the ECS service policy."
  value       = "${element(concat(aws_iam_policy.cluster_service_policy.*.arn, list("")), 0)}"
}

output "service_policy_id" {
  description = "The ID of the ECS service policy."
  value       = "${element(concat(aws_iam_policy.cluster_service_policy.*.id, list("")), 0)}"
}

output "log_group" {
  description = "The name of the default log group for the cluster."
  value       = "${element(concat(aws_cloudwatch_log_group.cluster.*.name, list("")), 0)}"
}

output "aws_autoscaling_scale_in_policy_arn" {
  value = aws_autoscaling_policy.dev_api_scale_in.arn
}

output "aws_autoscaling_scale_out_policy_arn" {
  value = aws_autoscaling_policy.dev_api_scale_out.arn
}

