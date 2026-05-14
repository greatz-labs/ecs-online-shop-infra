terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "ecs-fargate-dev-tfstate"
    key            = "ecs-online-shop/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "ecs-fargate-dev-tflock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.tags
  }
}

# ── VPC ───────────────────────────────────────────────────────────────────────

module "vpc" {
  count  = var.create_vpc ? 1 : 0
  source = "./modules/vpc"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  single_nat_gateway   = var.single_nat_gateway
  tags                 = var.tags
}

# ── ECR ───────────────────────────────────────────────────────────────────────

module "ecr" {
  count  = var.create_ecr ? 1 : 0
  source = "./modules/ecr"

  project_name = var.project_name
  environment  = var.environment
  name_suffix  = "products"
  tags         = var.tags
}

# ── IAM ───────────────────────────────────────────────────────────────────────

module "iam" {
  count  = var.create_iam ? 1 : 0
  source = "./modules/iam"

  project_name = var.project_name
  environment  = var.environment
  tags         = var.tags
}

# ── ALB ───────────────────────────────────────────────────────────────────────

module "alb" {
  count  = var.create_alb ? 1 : 0
  source = "./modules/alb"

  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = try(module.vpc[0].vpc_id, "")
  public_subnet_ids = try(module.vpc[0].public_subnet_ids, [])
  container_port    = var.container_port
  certificate_arn   = var.certificate_arn
  active_color      = var.active_color
  health_check_path = var.health_check_path
  tags              = var.tags
}

# ── ECS Cluster (shared by blue and green services) ───────────────────────────

module "ecs_cluster" {
  count  = var.create_cluster ? 1 : 0
  source = "./modules/ecs_cluster"

  project_name = var.project_name
  environment  = var.environment
  tags         = var.tags
}

# ── ECS Service — blue ────────────────────────────────────────────────────────

module "ecs_blue" {
  count  = var.create_ecs_blue ? 1 : 0
  source = "./modules/ecs_service"

  slot               = "blue"
  project_name       = var.project_name
  environment        = var.environment
  cluster_name       = try(module.ecs_cluster[0].cluster_name, "")
  vpc_id             = try(module.vpc[0].vpc_id, "")
  private_subnet_ids = try(module.vpc[0].private_subnet_ids, [])
  execution_role_arn = try(module.iam[0].execution_role_arn, "")
  task_role_arn      = try(module.iam[0].task_role_arn, "")
  ecr_repository_url = try(module.ecr[0].repository_url, "")
  target_group_arn   = try(module.alb[0].blue_target_group_arn, "")
  alb_security_group_id = try(module.alb[0].alb_security_group_id, "")
  container_port     = var.container_port
  cpu                = var.cpu
  memory             = var.memory
  desired_count      = var.blue_desired_count
  image_tag          = var.image_tag
  health_check_path  = var.health_check_path
  log_retention_days = var.log_retention_days
  environment_variables = {
    APP_COLOR               = "blue"
    APP_VERSION             = var.blue_version
    PYTHONDONTWRITEBYTECODE = "1"
  }
  tags = var.tags

  depends_on = [module.ecs_cluster]
}

# ── ECS Service — green ───────────────────────────────────────────────────────

module "ecs_green" {
  count  = var.create_ecs_green ? 1 : 0
  source = "./modules/ecs_service"

  slot               = "green"
  project_name       = var.project_name
  environment        = var.environment
  cluster_name       = try(module.ecs_cluster[0].cluster_name, "")
  vpc_id             = try(module.vpc[0].vpc_id, "")
  private_subnet_ids = try(module.vpc[0].private_subnet_ids, [])
  execution_role_arn = try(module.iam[0].execution_role_arn, "")
  task_role_arn      = try(module.iam[0].task_role_arn, "")
  ecr_repository_url = try(module.ecr[0].repository_url, "")
  target_group_arn   = try(module.alb[0].green_target_group_arn, "")
  alb_security_group_id = try(module.alb[0].alb_security_group_id, "")
  container_port     = var.container_port
  cpu                = var.cpu
  memory             = var.memory
  desired_count      = var.green_desired_count
  image_tag          = var.image_tag
  health_check_path  = var.health_check_path
  log_retention_days = var.log_retention_days
  environment_variables = {
    APP_COLOR               = "green"
    APP_VERSION             = var.green_version
    PYTHONDONTWRITEBYTECODE = "1"
  }
  tags = var.tags

  depends_on = [module.ecs_cluster]
}
