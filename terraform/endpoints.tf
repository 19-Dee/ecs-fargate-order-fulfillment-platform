resource "aws_vpc_endpoint" "ecr_api_ep" {
  vpc_id            = aws_vpc.ecs_project_vpc.id
  service_name      = "com.amazonaws.eu-west-2.ecr.api"
  vpc_endpoint_type = "Interface"

  subnet_ids = [
    aws_subnet.private_subnet_a.id,
    aws_subnet.private_subnet_b.id
  ]

  security_group_ids = [
    aws_security_group.ecr_api_ep_sg.id
  ]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ecr_dkr_ep" {
  vpc_id            = aws_vpc.ecs_project_vpc.id
  service_name      = "com.amazonaws.eu-west-2.ecr.dkr"
  vpc_endpoint_type = "Interface"

  subnet_ids = [
    aws_subnet.private_subnet_a.id,
    aws_subnet.private_subnet_b.id
  ]

  security_group_ids = [
    aws_security_group.ecr_dkr_ep_sg.id
  ]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "sqs_ep" {
  vpc_id            = aws_vpc.ecs_project_vpc.id
  service_name      = "com.amazonaws.eu-west-2.sqs"
  vpc_endpoint_type = "Interface"

  subnet_ids = [
    aws_subnet.private_subnet_a.id,
    aws_subnet.private_subnet_b.id
  ]

  security_group_ids = [
    aws_security_group.sqs_sg.id
  ]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "cloudwatch_ep" {
  vpc_id            = aws_vpc.ecs_project_vpc.id
  service_name      = "com.amazonaws.eu-west-2.logs"
  vpc_endpoint_type = "Interface"

  subnet_ids = [
    aws_subnet.private_subnet_a.id,
    aws_subnet.private_subnet_b.id
  ]

  security_group_ids = [
    aws_security_group.cloudwatch_logs_ep_sg.id
  ]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "secrets_manager_ep" {
  vpc_id            = aws_vpc.ecs_project_vpc.id
  service_name      = "com.amazonaws.eu-west-2.secretsmanager"
  vpc_endpoint_type = "Interface"

  subnet_ids = [
    aws_subnet.private_subnet_a.id,
    aws_subnet.private_subnet_b.id
  ]

  security_group_ids = [
    aws_security_group.secrets_manager_sg.id
  ]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "s3_gateway_ep" {
  vpc_id            = aws_vpc.ecs_project_vpc.id
  service_name      = "com.amazonaws.eu-west-2.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.private_rt.id
  ]
}
