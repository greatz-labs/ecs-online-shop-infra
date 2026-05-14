output "service_name" {
  description = "ECS service name"
  value       = aws_ecs_service.this.name
}

output "task_security_group_id" {
  description = "Security group ID attached to ECS tasks"
  value       = aws_security_group.task.id
}

output "task_definition_arn" {
  description = "ARN of the latest task definition revision"
  value       = aws_ecs_task_definition.this.arn
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch log group name for this service"
  value       = aws_cloudwatch_log_group.this.name
}
