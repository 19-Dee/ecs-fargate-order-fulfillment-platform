resource "aws_secretsmanager_secret" "database_url" {
  name_prefix = "ecs-project-database-url-"
  description = "PostgreSQL connection string for ECS services"
}

resource "aws_secretsmanager_secret_version" "database_url" {
  secret_id = aws_secretsmanager_secret.database_url.id

  secret_string = "postgres://${var.db_username}:${var.db_password}@${aws_db_instance.orders_db.address}:5432/orders_db?sslmode=require"
}
