resource "aws_security_group" "alb_sg" {
  name        = "alb_sg"
  description = "Allow HTTP and TLS inbound traffic"
  vpc_id      = aws_vpc.ecs_project_vpc.id
}

resource "aws_security_group" "ecs_sg" {
  name        = "ecs_sg"
  description = "Allow API gateway traffic from ALB to ECS tasks"
  vpc_id      = aws_vpc.ecs_project_vpc.id
}

resource "aws_security_group" "ecr_api_ep_sg" {
  name        = "ecr_api_ep_sg"
  description = "Allow HTTPS from ECS tasks to ECR API endpoint"
  vpc_id      = aws_vpc.ecs_project_vpc.id
}

resource "aws_security_group" "ecr_dkr_ep_sg" {
  name        = "ecr_dkr_ep_sg"
  description = "Allow HTTPS from ECS tasks to the ECR Docker Registry endpoint"
  vpc_id      = aws_vpc.ecs_project_vpc.id
}

resource "aws_security_group" "sqs_sg" {
  name        = "sqs_sg"
  description = "Allow traffic from certain ECS tasks to SQS"
  vpc_id      = aws_vpc.ecs_project_vpc.id
}

resource "aws_security_group" "secrets_manager_sg" {
  name        = "secrets_manager_sg"
  description = "Allow HTTPS from ECS tasks to Secrets Manager endpoint"
  vpc_id      = aws_vpc.ecs_project_vpc.id
}

resource "aws_security_group" "cloudwatch_logs_ep_sg" {
  name        = "cloudwatch_logs_ep_sg"
  description = "Allow HTTPS from ECS tasks to CloudWatch Logs endpoint"
  vpc_id      = aws_vpc.ecs_project_vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_ipv4" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_alb_to_ecs" {
  security_group_id            = aws_security_group.ecs_sg.id
  referenced_security_group_id = aws_security_group.alb_sg.id
  from_port                    = 8080
  ip_protocol                  = "tcp"
  to_port                      = 8080
}

resource "aws_vpc_security_group_ingress_rule" "allow_ecs_to_ecs" {
  security_group_id            = aws_security_group.ecs_sg.id
  referenced_security_group_id = aws_security_group.ecs_sg.id
  from_port                    = 8081
  ip_protocol                  = "tcp"
  to_port                      = 8086
}

resource "aws_vpc_security_group_ingress_rule" "allow_ecs_to_ecr_api" {
  security_group_id            = aws_security_group.ecr_api_ep_sg.id
  referenced_security_group_id = aws_security_group.ecs_sg.id
  from_port                    = 443
  ip_protocol                  = "tcp"
  to_port                      = 443
}

resource "aws_vpc_security_group_ingress_rule" "allow_ecs_to_ecr_dkr" {
  security_group_id            = aws_security_group.ecr_dkr_ep_sg.id
  referenced_security_group_id = aws_security_group.ecs_sg.id
  from_port                    = 443
  ip_protocol                  = "tcp"
  to_port                      = 443
}

resource "aws_vpc_security_group_ingress_rule" "allow_ecs_to_sqs" {
  security_group_id            = aws_security_group.sqs_sg.id
  referenced_security_group_id = aws_security_group.ecs_sg.id
  from_port                    = 443
  ip_protocol                  = "tcp"
  to_port                      = 443
}

resource "aws_vpc_security_group_ingress_rule" "allow_ecs_to_cloudwatch_logs" {
  security_group_id            = aws_security_group.cloudwatch_logs_ep_sg.id
  referenced_security_group_id = aws_security_group.ecs_sg.id
  from_port                    = 443
  ip_protocol                  = "tcp"
  to_port                      = 443
}

resource "aws_vpc_security_group_ingress_rule" "allow_ecs_to_secrets_manager" {
  security_group_id            = aws_security_group.secrets_manager_sg.id
  referenced_security_group_id = aws_security_group.ecs_sg.id
  from_port                    = 443
  ip_protocol                  = "tcp"
  to_port                      = 443
}
