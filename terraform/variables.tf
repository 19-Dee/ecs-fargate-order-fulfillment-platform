variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "app_admin"
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

variable "ecs_desired_count" {
  description = "Number of tasks to run for each ECS service"
  type        = number
  default     = 1
}

variable "cloudwatch_alarm_actions" {
  description = "SNS topic ARNs notified when CloudWatch alarms enter or leave ALARM state"
  type        = list(string)
  default     = []
}
