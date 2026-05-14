variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 8080
}

variable "certificate_arn" {
  description = "ACM certificate ARN. When set, an HTTPS listener is created and HTTP redirects to it."
  type        = string
  default     = ""
}

variable "active_color" {
  description = "Which slot receives 100% of traffic (blue or green). Change and re-apply to cut over."
  type        = string
  default     = "blue"

  validation {
    condition     = contains(["blue", "green"], var.active_color)
    error_message = "active_color must be \"blue\" or \"green\"."
  }
}

variable "health_check_path" {
  description = "Path the ALB uses to health-check tasks"
  type        = string
  default     = "/health"
}

variable "health_check_interval" {
  type    = number
  default = 30
}

variable "health_check_healthy_threshold" {
  type    = number
  default = 3
}

variable "health_check_unhealthy_threshold" {
  type    = number
  default = 3
}

variable "deregistration_delay" {
  description = "Seconds ALB waits before deregistering a draining target"
  type        = number
  default     = 30
}

variable "tags" {
  type    = map(string)
  default = {}
}
