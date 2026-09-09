terraform {
  backend "s3" {
    bucket       = "dishen-ecs-project-terraform-state"
    key          = "ecs-project/terraform.tfstate"
    region       = "eu-west-2"
    use_lockfile = true
    encrypt      = true
  }
}
