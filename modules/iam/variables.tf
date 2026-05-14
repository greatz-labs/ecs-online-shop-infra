variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "task_role_policy_arns" {
  description = "Additional managed policy ARNs to attach to the task role (e.g. S3, DynamoDB)"
  type        = list(string)
  default     = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
