output "alb_dns_name" {
  description = "ALB DNS name — point your domain's CNAME or Route53 alias here"
  value       = try(module.alb[0].alb_dns_name, null)
}

output "ecr_repository_url" {
  description = "ECR repository URL — used in docker push and task definitions"
  value       = try(module.ecr[0].repository_url, null)
}

output "cluster_name" {
  description = "ECS cluster name (shared by blue and green)"
  value       = try(module.ecs_cluster[0].cluster_name, null)
}

output "blue_service_name" {
  description = "Blue ECS service name"
  value       = try(module.ecs_blue[0].service_name, null)
}

output "green_service_name" {
  description = "Green ECS service name"
  value       = try(module.ecs_green[0].service_name, null)
}

output "blue_log_group" {
  description = "CloudWatch log group for blue tasks"
  value       = try(module.ecs_blue[0].cloudwatch_log_group_name, null)
}

output "green_log_group" {
  description = "CloudWatch log group for green tasks"
  value       = try(module.ecs_green[0].cloudwatch_log_group_name, null)
}

output "blue_target_group_arn" {
  description = "Blue ALB target group ARN"
  value       = try(module.alb[0].blue_target_group_arn, null)
}

output "green_target_group_arn" {
  description = "Green ALB target group ARN"
  value       = try(module.alb[0].green_target_group_arn, null)
}
