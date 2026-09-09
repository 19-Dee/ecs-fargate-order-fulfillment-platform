resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name = "redis-subnet-group"
  subnet_ids = [
    aws_subnet.private_subnet_a.id,
    aws_subnet.private_subnet_b.id
  ]
}

resource "aws_elasticache_replication_group" "redis" {
  automatic_failover_enabled = false
  engine                     = "redis"
  replication_group_id       = "ecs-project-redis"
  description                = "Redis for ECS order fulfillment platform"
  node_type                  = "cache.t4g.micro"
  num_cache_clusters         = 1
  port                       = 6379
  subnet_group_name          = aws_elasticache_subnet_group.redis_subnet_group.name
  security_group_ids         = [aws_security_group.redis_sg.id]
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
}
