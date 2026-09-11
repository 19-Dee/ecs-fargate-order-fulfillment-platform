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

resource "aws_ecs_task_definition" "api_gateway" {
  family                   = "api_gateway"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "api-gateway"
      image     = "${aws_ecr_repository.api-gateway.repository_url}:initial"
      cpu       = 256
      memory    = 512
      essential = true

      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
        }
      ]

      environment = [
        {
          name  = "REDIS_URL"
          value = "rediss://${aws_elasticache_replication_group.redis.primary_endpoint_address}:6379"
        },
        {
          name  = "ORDER_SERVICE_URL"
          value = "http://order-service:8081"
        },
        {
          name  = "INVENTORY_SERVICE_URL"
          value = "http://inventory-service:8082"
        },
        {
          name  = "PAYMENT_SERVICE_URL"
          value = "http://payment-service:8083"
        },
        {
          name  = "NOTIFICATION_SERVICE_URL"
          value = "http://notification-service:8084"
        },
        {
          name  = "SHIPPING_SERVICE_URL"
          value = "http://shipping-service:8085"
        },
        {
          name  = "DASHBOARD_SERVICE_URL"
          value = "http://dashboard-api:8086"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.api_gateway.name
          "awslogs-region"        = "eu-west-2"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_task_definition" "order_service" {
  family                   = "order_service"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  task_role_arn            = aws_iam_role.order_service_task_role.arn
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "order-service"
      image     = "${aws_ecr_repository.order-service.repository_url}:initial"
      cpu       = 256
      memory    = 512
      essential = true

      portMappings = [
        {
          name          = "order-service"
          containerPort = 8081
          hostPort      = 8081
        }
      ]

      secrets = [
        {
          name      = "DATABASE_URL"
          valueFrom = aws_secretsmanager_secret.database_url.arn
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.order_service.name
          "awslogs-region"        = "eu-west-2"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  depends_on = [
    aws_secretsmanager_secret_version.database_url
  ]
}

resource "aws_ecs_task_definition" "inventory_service" {
  family                   = "inventory_service"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "inventory-service"
      image     = "${aws_ecr_repository.inventory-service.repository_url}:initial"
      cpu       = 256
      memory    = 512
      essential = true

      portMappings = [
        {
          name          = "inventory-service"
          containerPort = 8082
          hostPort      = 8082
        }
      ]

      secrets = [
        {
          name      = "DATABASE_URL"
          valueFrom = aws_secretsmanager_secret.database_url.arn
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.inventory_service.name
          "awslogs-region"        = "eu-west-2"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  depends_on = [
    aws_secretsmanager_secret_version.database_url
  ]
}

resource "aws_ecs_task_definition" "payment_service" {
  family                   = "payment_service"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "payment-service"
      image     = "${aws_ecr_repository.payment-service.repository_url}:initial"
      cpu       = 256
      memory    = 512
      essential = true

      portMappings = [
        {
          name          = "payment-service"
          containerPort = 8083
          hostPort      = 8083
        }
      ]

      secrets = [
        {
          name      = "DATABASE_URL"
          valueFrom = aws_secretsmanager_secret.database_url.arn
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.payment_service.name
          "awslogs-region"        = "eu-west-2"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  depends_on = [
    aws_secretsmanager_secret_version.database_url
  ]
}

resource "aws_ecs_task_definition" "notification_service" {
  family                   = "notification_service"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "notification-service"
      image     = "${aws_ecr_repository.notification-service.repository_url}:initial"
      cpu       = 256
      memory    = 512
      essential = true

      portMappings = [
        {
          name          = "notification-service"
          containerPort = 8084
          hostPort      = 8084
        }
      ]

      secrets = [
        {
          name      = "DATABASE_URL"
          valueFrom = aws_secretsmanager_secret.database_url.arn
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.notification_service.name
          "awslogs-region"        = "eu-west-2"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  depends_on = [
    aws_secretsmanager_secret_version.database_url
  ]
}

resource "aws_ecs_task_definition" "shipping_service" {
  family                   = "shipping_service"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "shipping-service"
      image     = "${aws_ecr_repository.shipping-service.repository_url}:initial"
      cpu       = 256
      memory    = 512
      essential = true

      portMappings = [
        {
          name          = "shipping-service"
          containerPort = 8085
          hostPort      = 8085
        }
      ]

      secrets = [
        {
          name      = "DATABASE_URL"
          valueFrom = aws_secretsmanager_secret.database_url.arn
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.shipping_service.name
          "awslogs-region"        = "eu-west-2"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  depends_on = [
    aws_secretsmanager_secret_version.database_url
  ]
}

resource "aws_ecs_task_definition" "dashboard_api" {
  family                   = "dashboard_api"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "dashboard-api"
      image     = "${aws_ecr_repository.dashboard-api.repository_url}:initial"
      cpu       = 256
      memory    = 512
      essential = true

      portMappings = [
        {
          name          = "dashboard-api"
          containerPort = 8086
          hostPort      = 8086
        }
      ]

      secrets = [
        {
          name      = "DATABASE_URL"
          valueFrom = aws_secretsmanager_secret.database_url.arn
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.dashboard_api.name
          "awslogs-region"        = "eu-west-2"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  depends_on = [
    aws_secretsmanager_secret_version.database_url
  ]
}

resource "aws_ecs_task_definition" "worker" {
  family                   = "worker"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  task_role_arn            = aws_iam_role.worker_task_role.arn
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "worker"
      image     = "${aws_ecr_repository.worker.repository_url}:sqs-polling-v1"
      cpu       = 256
      memory    = 512
      essential = true

      portMappings = [
        {
          containerPort = 8090
          hostPort      = 8090
        }
      ]

      environment = [
        {
          name  = "SQS_QUEUE_URL"
          value = aws_sqs_queue.ecs_v3_queue.id
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.worker.name
          "awslogs-region"        = "eu-west-2"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_task_definition" "scheduler" {
  family                   = "scheduler"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "scheduler"
      image     = "${aws_ecr_repository.scheduler.repository_url}:initial"
      cpu       = 256
      memory    = 512
      essential = true

      portMappings = [
        {
          containerPort = 8091
          hostPort      = 8091
        }
      ]

      secrets = [
        {
          name      = "DATABASE_URL"
          valueFrom = aws_secretsmanager_secret.database_url.arn
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.scheduler.name
          "awslogs-region"        = "eu-west-2"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  depends_on = [
    aws_secretsmanager_secret_version.database_url
  ]
}

resource "aws_ecs_service" "api_gateway" {
  name            = "api-gateway"
  cluster         = aws_ecs_cluster.ecs_project_cluster.id
  task_definition = aws_ecs_task_definition.api_gateway.arn
  desired_count   = var.ecs_desired_count

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_project_alb.arn
    container_name   = "api-gateway"
    container_port   = 8080
  }

  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    base              = 1
    weight            = 100
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    security_groups  = [aws_security_group.ecs_sg.id]
    subnets          = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]
    assign_public_ip = false
  }

  depends_on = [
    aws_ecs_cluster_capacity_providers.ecs_project_fargate
  ]


  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_http_namespace.ecs_services.arn
  }
}

resource "aws_ecs_service" "order_service" {
  name            = "order-service"
  cluster         = aws_ecs_cluster.ecs_project_cluster.id
  task_definition = aws_ecs_task_definition.order_service.arn
  desired_count   = var.ecs_desired_count

  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    base              = 1
    weight            = 100
  }

  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_http_namespace.ecs_services.arn

    service {
      port_name      = "order-service"
      discovery_name = "order-service"

      client_alias {
        dns_name = "order-service"
        port     = 8081
      }
    }
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    security_groups  = [aws_security_group.ecs_sg.id]
    subnets          = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]
    assign_public_ip = false
  }

  depends_on = [
    aws_ecs_cluster_capacity_providers.ecs_project_fargate
  ]
}

resource "aws_ecs_service" "inventory_service" {
  name            = "inventory-service"
  cluster         = aws_ecs_cluster.ecs_project_cluster.id
  task_definition = aws_ecs_task_definition.inventory_service.arn
  desired_count   = var.ecs_desired_count

  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    base              = 1
    weight            = 100
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    security_groups  = [aws_security_group.ecs_sg.id]
    subnets          = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]
    assign_public_ip = false
  }

  depends_on = [
    aws_ecs_cluster_capacity_providers.ecs_project_fargate
  ]


  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_http_namespace.ecs_services.arn

    service {
      port_name      = "inventory-service"
      discovery_name = "inventory-service"

      client_alias {
        dns_name = "inventory-service"
        port     = 8082
      }
    }
  }
}

resource "aws_ecs_service" "payment_service" {
  name            = "payment-service"
  cluster         = aws_ecs_cluster.ecs_project_cluster.id
  task_definition = aws_ecs_task_definition.payment_service.arn
  desired_count   = var.ecs_desired_count

  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    base              = 1
    weight            = 100
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    security_groups  = [aws_security_group.ecs_sg.id]
    subnets          = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]
    assign_public_ip = false
  }

  depends_on = [
    aws_ecs_cluster_capacity_providers.ecs_project_fargate
  ]


  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_http_namespace.ecs_services.arn

    service {
      port_name      = "payment-service"
      discovery_name = "payment-service"

      client_alias {
        dns_name = "payment-service"
        port     = 8083
      }
    }
  }
}

resource "aws_ecs_service" "notification_service" {
  name            = "notification-service"
  cluster         = aws_ecs_cluster.ecs_project_cluster.id
  task_definition = aws_ecs_task_definition.notification_service.arn
  desired_count   = var.ecs_desired_count

  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    base              = 1
    weight            = 100
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    security_groups  = [aws_security_group.ecs_sg.id]
    subnets          = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]
    assign_public_ip = false
  }

  depends_on = [
    aws_ecs_cluster_capacity_providers.ecs_project_fargate
  ]


  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_http_namespace.ecs_services.arn

    service {
      port_name      = "notification-service"
      discovery_name = "notification-service"

      client_alias {
        dns_name = "notification-service"
        port     = 8084
      }
    }
  }
}

resource "aws_ecs_service" "shipping_service" {
  name            = "shipping-service"
  cluster         = aws_ecs_cluster.ecs_project_cluster.id
  task_definition = aws_ecs_task_definition.shipping_service.arn
  desired_count   = var.ecs_desired_count

  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    base              = 1
    weight            = 100
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    security_groups  = [aws_security_group.ecs_sg.id]
    subnets          = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]
    assign_public_ip = false
  }

  depends_on = [
    aws_ecs_cluster_capacity_providers.ecs_project_fargate
  ]


  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_http_namespace.ecs_services.arn

    service {
      port_name      = "shipping-service"
      discovery_name = "shipping-service"

      client_alias {
        dns_name = "shipping-service"
        port     = 8085
      }
    }
  }
}

resource "aws_ecs_service" "dashboard_api" {
  name            = "dashboard-api"
  cluster         = aws_ecs_cluster.ecs_project_cluster.id
  task_definition = aws_ecs_task_definition.dashboard_api.arn
  desired_count   = var.ecs_desired_count

  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    base              = 1
    weight            = 100
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.dashboard_api.arn
    container_name   = "dashboard-api"
    container_port   = 8086
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    security_groups  = [aws_security_group.ecs_sg.id]
    subnets          = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]
    assign_public_ip = false
  }

  depends_on = [
    aws_ecs_cluster_capacity_providers.ecs_project_fargate
  ]


  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_http_namespace.ecs_services.arn

    service {
      port_name      = "dashboard-api"
      discovery_name = "dashboard-api"

      client_alias {
        dns_name = "dashboard-api"
        port     = 8086
      }
    }
  }
}

resource "aws_ecs_service" "worker" {
  name            = "worker"
  cluster         = aws_ecs_cluster.ecs_project_cluster.id
  task_definition = aws_ecs_task_definition.worker.arn
  desired_count   = var.ecs_desired_count

  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    base              = 1
    weight            = 100
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    security_groups  = [aws_security_group.ecs_sg.id]
    subnets          = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]
    assign_public_ip = false
  }

  depends_on = [
    aws_ecs_cluster_capacity_providers.ecs_project_fargate
  ]
}

resource "aws_ecs_service" "scheduler" {
  name            = "scheduler"
  cluster         = aws_ecs_cluster.ecs_project_cluster.id
  task_definition = aws_ecs_task_definition.scheduler.arn
  desired_count   = var.ecs_desired_count

  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    base              = 1
    weight            = 100
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    security_groups  = [aws_security_group.ecs_sg.id]
    subnets          = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]
    assign_public_ip = false
  }

  depends_on = [
    aws_ecs_cluster_capacity_providers.ecs_project_fargate
  ]
}

resource "aws_service_discovery_http_namespace" "ecs_services" {
  name = "ecs-services"
}
