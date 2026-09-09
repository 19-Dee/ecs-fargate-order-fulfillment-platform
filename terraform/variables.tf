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
