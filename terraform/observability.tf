locals {
  ecs_service_names = [
    aws_ecs_service.api_gateway.name,
    aws_ecs_service.order_service.name,
    aws_ecs_service.inventory_service.name,
    aws_ecs_service.payment_service.name,
    aws_ecs_service.notification_service.name,
    aws_ecs_service.shipping_service.name,
    aws_ecs_service.dashboard_api.name,
    aws_ecs_service.worker.name,
    aws_ecs_service.scheduler.name
  ]
}

resource "aws_cloudwatch_dashboard" "operations" {
  dashboard_name = "ecs-order-fulfillment-operations"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 24
        height = 6

        properties = {
          title  = "ECS running tasks by service"
          view   = "timeSeries"
          region = "eu-west-2"
          stat   = "Minimum"
          period = 60
          metrics = [
            for service_name in local.ecs_service_names : [
              "ECS/ContainerInsights",
              "RunningTaskCount",
              "ServiceName",
              service_name,
              "ClusterName",
              aws_ecs_cluster.ecs_project_cluster.name
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          title  = "ECS CPU utilization"
          view   = "timeSeries"
          region = "eu-west-2"
          stat   = "Average"
          period = 300
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
          metrics = [
            for service_name in local.ecs_service_names : [
              "AWS/ECS",
              "CPUUtilization",
              "ServiceName",
              service_name,
              "ClusterName",
              aws_ecs_cluster.ecs_project_cluster.name
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6

        properties = {
          title  = "ECS memory utilization"
          view   = "timeSeries"
          region = "eu-west-2"
          stat   = "Average"
          period = 300
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
          metrics = [
            for service_name in local.ecs_service_names : [
              "AWS/ECS",
              "MemoryUtilization",
              "ServiceName",
              service_name,
              "ClusterName",
              aws_ecs_cluster.ecs_project_cluster.name
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6

        properties = {
          title  = "ALB requests, 5xx responses, and unhealthy targets"
          view   = "timeSeries"
          region = "eu-west-2"
          period = 300
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.ecs_project_alb.arn_suffix, { stat = "Sum" }],
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", aws_lb.ecs_project_alb.arn_suffix, { stat = "Sum" }],
            ["AWS/ApplicationELB", "UnHealthyHostCount", "TargetGroup", aws_lb_target_group.ecs_project_alb.arn_suffix, "LoadBalancer", aws_lb.ecs_project_alb.arn_suffix, { stat = "Maximum" }],
            ["AWS/ApplicationELB", "UnHealthyHostCount", "TargetGroup", aws_lb_target_group.dashboard_api.arn_suffix, "LoadBalancer", aws_lb.ecs_project_alb.arn_suffix, { stat = "Maximum" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 12
        width  = 12
        height = 6

        properties = {
          title  = "SQS backlog and oldest message age"
          view   = "timeSeries"
          region = "eu-west-2"
          period = 300
          metrics = [
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", aws_sqs_queue.ecs_v3_queue.name, { stat = "Maximum" }],
            ["AWS/SQS", "ApproximateNumberOfMessagesNotVisible", "QueueName", aws_sqs_queue.ecs_v3_queue.name, { stat = "Maximum" }],
            ["AWS/SQS", "ApproximateAgeOfOldestMessage", "QueueName", aws_sqs_queue.ecs_v3_queue.name, { stat = "Maximum", yAxis = "right" }],
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", aws_sqs_queue.ecs_v3_queue_deadletter.name, { stat = "Maximum" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 18
        width  = 24
        height = 6

        properties = {
          title  = "RDS CPU, connections, and free storage"
          view   = "timeSeries"
          region = "eu-west-2"
          period = 300
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", aws_db_instance.orders_db.identifier, { stat = "Average" }],
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", aws_db_instance.orders_db.identifier, { stat = "Maximum" }],
            ["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", aws_db_instance.orders_db.identifier, { stat = "Minimum", yAxis = "right" }]
          ]
        }
      }
    ]
  })
}

resource "aws_cloudwatch_metric_alarm" "ecs_service_not_running" {
  alarm_name          = "ecs-any-service-not-running"
  alarm_description   = "At least one expected ECS service has no running task."
  comparison_operator = "LessThanThreshold"
  threshold           = 1
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  treat_missing_data  = "breaching"
  alarm_actions       = var.cloudwatch_alarm_actions
  ok_actions          = var.cloudwatch_alarm_actions

  metric_query {
    id          = "minimum_running_tasks"
    expression  = "MIN(METRICS(\"service_\"))"
    label       = "Minimum running task count"
    return_data = true
  }

  dynamic "metric_query" {
    for_each = {
      for index, service_name in local.ecs_service_names : "service_${index}" => service_name
    }

    content {
      id          = metric_query.key
      return_data = false

      metric {
        namespace   = "ECS/ContainerInsights"
        metric_name = "RunningTaskCount"
        period      = 60
        stat        = "Minimum"

        dimensions = {
          ClusterName = aws_ecs_cluster.ecs_project_cluster.name
          ServiceName = metric_query.value
        }
      }
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_targets" {
  alarm_name          = "alb-unhealthy-targets"
  alarm_description   = "The API gateway or dashboard target group has an unhealthy target."
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.cloudwatch_alarm_actions
  ok_actions          = var.cloudwatch_alarm_actions

  metric_query {
    id          = "maximum_unhealthy_targets"
    expression  = "MAX(METRICS(\"target_\"))"
    label       = "Maximum unhealthy target count"
    return_data = true
  }

  metric_query {
    id          = "target_api"
    return_data = false

    metric {
      namespace   = "AWS/ApplicationELB"
      metric_name = "UnHealthyHostCount"
      period      = 60
      stat        = "Maximum"

      dimensions = {
        LoadBalancer = aws_lb.ecs_project_alb.arn_suffix
        TargetGroup  = aws_lb_target_group.ecs_project_alb.arn_suffix
      }
    }
  }

  metric_query {
    id          = "target_dashboard"
    return_data = false

    metric {
      namespace   = "AWS/ApplicationELB"
      metric_name = "UnHealthyHostCount"
      period      = 60
      stat        = "Maximum"

      dimensions = {
        LoadBalancer = aws_lb.ecs_project_alb.arn_suffix
        TargetGroup  = aws_lb_target_group.dashboard_api.arn_suffix
      }
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_target_5xx" {
  alarm_name          = "alb-target-5xx"
  alarm_description   = "Targets returned at least five 5xx responses in five minutes."
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_Target_5XX_Count"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 5
  evaluation_periods  = 1
  period              = 300
  statistic           = "Sum"
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.cloudwatch_alarm_actions
  ok_actions          = var.cloudwatch_alarm_actions

  dimensions = {
    LoadBalancer = aws_lb.ecs_project_alb.arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "sqs_backlog" {
  alarm_name          = "sqs-order-backlog"
  alarm_description   = "The order queue has more than 100 visible messages for ten minutes."
  namespace           = "AWS/SQS"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 100
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  period              = 300
  statistic           = "Maximum"
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.cloudwatch_alarm_actions
  ok_actions          = var.cloudwatch_alarm_actions

  dimensions = {
    QueueName = aws_sqs_queue.ecs_v3_queue.name
  }
}

resource "aws_cloudwatch_metric_alarm" "sqs_deadletter_messages" {
  alarm_name          = "sqs-deadletter-messages"
  alarm_description   = "At least one message is visible in the dead-letter queue."
  namespace           = "AWS/SQS"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0
  evaluation_periods  = 1
  period              = 60
  statistic           = "Maximum"
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.cloudwatch_alarm_actions
  ok_actions          = var.cloudwatch_alarm_actions

  dimensions = {
    QueueName = aws_sqs_queue.ecs_v3_queue_deadletter.name
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "rds-high-cpu"
  alarm_description   = "RDS CPU utilization is above 80 percent for ten minutes."
  namespace           = "AWS/RDS"
  metric_name         = "CPUUtilization"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 80
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  period              = 300
  statistic           = "Average"
  treat_missing_data  = "missing"
  alarm_actions       = var.cloudwatch_alarm_actions
  ok_actions          = var.cloudwatch_alarm_actions

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.orders_db.identifier
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_connections" {
  alarm_name          = "rds-high-connections"
  alarm_description   = "RDS has more than 80 open database connections for ten minutes."
  namespace           = "AWS/RDS"
  metric_name         = "DatabaseConnections"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 80
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  period              = 300
  statistic           = "Maximum"
  treat_missing_data  = "missing"
  alarm_actions       = var.cloudwatch_alarm_actions
  ok_actions          = var.cloudwatch_alarm_actions

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.orders_db.identifier
  }
}
