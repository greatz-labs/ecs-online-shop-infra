aws_region   = "us-east-1"
project_name = "ecs-online-shop"
environment  = "dev"

# Different CIDR range from ecs-fargate-project to avoid overlap if VPCs are peered later
vpc_cidr             = "10.1.0.0/16"
public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24"]
private_subnet_cidrs = ["10.1.11.0/24", "10.1.12.0/24"]
availability_zones   = ["us-east-1a", "us-east-1b"]
single_nat_gateway   = true # saves ~$33/mo in dev

tags = {
  Owner = "platform-team"
  Repo  = "ecs-online-shop-infra"
}

# ── Container / ECS ───────────────────────────────────────────────────────────
container_port     = 8080
health_check_path  = "/health"
cpu                = "256"
memory             = "512"
image_tag          = "latest" # replace with git SHA in CI
log_retention_days = 365

# ── Blue-Green ────────────────────────────────────────────────────────────────
# Cutover: change active_color + bump standby desired_count to match active,
# then apply. Scale down old active only after validating the new one.
active_color        = "blue"
blue_desired_count  = 1
green_desired_count = 0
blue_version        = "1.0.0"
green_version       = "2.0.0"

# ── Module toggles ────────────────────────────────────────────────────────────
# Enable in order: ecr → push image → cluster + iam + alb + ecs
create_vpc     = true
create_ecr     = true
create_iam     = true
create_alb     = true
create_cluster = true
create_ecs_blue  = true
create_ecs_green = true
