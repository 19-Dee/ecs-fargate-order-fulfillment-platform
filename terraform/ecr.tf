resource "aws_ecr_repository" "api-gateway" {
  name                 = "api-gateway"
  image_tag_mutability = "MUTABLE" // Allows to reuse the same tag name and overwrite what that tag points to

  image_scanning_configuration {
    scan_on_push = true // registry-side vulnerability visibility
  }
}

resource "aws_ecr_repository" "dashboard-api" {
  name                 = "dashboard-api"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "inventory-service" {
  name                 = "inventory-service"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "notification-service" {
  name                 = "notification-service"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "order-service" {
  name                 = "order-service"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "payment-service" {
  name                 = "payment-service"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "scheduler" {
  name                 = "scheduler"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "shipping-service" {
  name                 = "shipping-service"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "worker" {
  name                 = "worker"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
