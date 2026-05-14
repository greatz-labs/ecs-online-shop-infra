variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "slot" {
  description = "Deployment slot (blue or green)"
  type        = string

  validation {
    condition     = contains(["blue", "green"], var.slot)
    error_message = "slot must be \"blue\" or \"green\"."
  }
}

variable "cluster_name" {
  description = "Name of the existing ECS cluster to deploy this service into"
  type        = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "execution_role_arn" {
  description = "ARN of the ECS task execution role"
  type        = string
  default     = ""
}

variable "task_role_arn" {
  description = "ARN of the ECS task role"
  type        = string
  default     = ""
}

variable "ecr_repository_url" {
  description = "ECR repository URL used as the container image base"
  type        = string
  default     = ""
}

variable "target_group_arn" {
  description = "ALB target group ARN"
  type        = string
  default     = ""
}

variable "alb_security_group_id" {
  description = "ALB security group ID — ECS task SG allows ingress from this only"
  type        = string
  default     = ""
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 8080
}

variable "cpu" {
  description = "Fargate task CPU units (256 / 512 / 1024 / 2048 / 4096)"
  type        = string
  default     = "256"
}

variable "memory" {
  description = "Fargate task memory in MiB"
  type        = string
  default     = "512"
}

variable "desired_count" {
  description = "Number of tasks to keep running"
  type        = number
  default     = 1
}

variable "image_tag" {
  description = "Container image tag. Use a git SHA in production, not 'latest'."
  type        = string
  default     = "latest"
}

variable "health_check_path" {
  description = "Path used for ALB and container-level health checks"
  type        = string
  default     = "/health"
}

variable "health_check_grace_period" {
  description = "Seconds ECS waits before checking ALB health on new tasks"
  type        = number
  default     = 60
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 365
}

variable "environment_variables" {
  description = "Non-sensitive environment variables injected into the container"
  type        = map(string)
  default     = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
