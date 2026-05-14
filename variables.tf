variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name — used as a prefix for all resource names"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
}

# ── Networking ────────────────────────────────────────────────────────────────

variable "vpc_cidr" {
  type    = string
  default = "10.1.0.0/16"
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.1.1.0/24", "10.1.2.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.1.11.0/24", "10.1.12.0/24"]
}

variable "availability_zones" {
  type = list(string)
}

variable "single_nat_gateway" {
  description = "Use one NAT gateway instead of one per AZ. Saves ~$33/mo in dev."
  type        = bool
  default     = true
}

# ── Container / ECS ───────────────────────────────────────────────────────────

variable "container_port" {
  type    = number
  default = 8080
}

variable "health_check_path" {
  type    = string
  default = "/health"
}

variable "cpu" {
  type    = string
  default = "256"
}

variable "memory" {
  type    = string
  default = "512"
}

variable "image_tag" {
  description = "Image tag to deploy. Use a git SHA in CI, not 'latest'."
  type        = string
  default     = "latest"
}

variable "log_retention_days" {
  type    = number
  default = 365
}

# ── Blue-Green ────────────────────────────────────────────────────────────────

variable "active_color" {
  description = "Slot receiving 100% of ALB traffic. Change + apply to cut over."
  type        = string
  default     = "blue"

  validation {
    condition     = contains(["blue", "green"], var.active_color)
    error_message = "active_color must be \"blue\" or \"green\"."
  }
}

variable "blue_desired_count" {
  description = "Number of blue tasks to run (0 = scaled down)"
  type        = number
  default     = 1
}

variable "green_desired_count" {
  description = "Number of green tasks to run (0 = scaled down)"
  type        = number
  default     = 0
}

variable "blue_version" {
  description = "App version string injected as APP_VERSION into blue tasks"
  type        = string
  default     = "1.0.0"
}

variable "green_version" {
  description = "App version string injected as APP_VERSION into green tasks"
  type        = string
  default     = "2.0.0"
}


# ── Module toggles ────────────────────────────────────────────────────────────

variable "create_vpc" {
  type    = bool
  default = true
}

variable "create_ecr" {
  type    = bool
  default = true
}

variable "create_iam" {
  type    = bool
  default = true
}

variable "create_alb" {
  type    = bool
  default = true
}

variable "create_cluster" {
  description = "Create the shared ECS cluster"
  type        = bool
  default     = true
}

variable "create_ecs_blue" {
  description = "Create the blue ECS service and task definition"
  type        = bool
  default     = true
}

variable "create_ecs_green" {
  description = "Create the green ECS service and task definition"
  type        = bool
  default     = true
}

# ── Tags ──────────────────────────────────────────────────────────────────────

variable "tags" {
  description = "Tags applied to all resources via provider default_tags"
  type        = map(string)
  default     = {}
}
