resource "aws_ecs_cluster" "ecs_project_cluster" {
  name = "dishen-ecs-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "ecs_project_fargate" {
  cluster_name = aws_ecs_cluster.ecs_project_cluster.name

  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}
