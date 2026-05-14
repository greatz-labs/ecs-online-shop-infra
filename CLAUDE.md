# Working Preferences

## Compaction
- Run /compact manually at ~50% context usage, not automatic
- On compact, always preserve: modified files, current module status,
  unresolved decisions, open security flags

## IaC
- Modular, DRY. Flag security risks immediately, including hardcoded secrets.
- Minimum code that solves the problem. Nothing speculative.
- Touch only what you must. Clean up only your own mess.
- Inline comments on non-obvious logic only.
- YAML over JSON where both are valid.

## General
- Skip DevOps basics. Keep CLI explanations brief.
- Don't assume. Don't hide confusion. Surface tradeoffs explicitly.
- Define success criteria. Loop until verified.
- Clear, direct output. No filler.

# ECS Online Shop — Infra Repo

## Purpose
Terraform infrastructure for the Products CRUD API blue-green deployment demo.
Companion app repo: `ecs-online-shop-app`.

## Stack
- Terraform >= 1.5
- Fargate launch type, dedicated VPC (10.1.0.0/16)
- S3 backend: `ecs-fargate-dev-tfstate`, key `ecs-online-shop/dev/terraform.tfstate`
- DynamoDB lock: `ecs-fargate-dev-tflock`
- GitHub Actions OIDC — no static keys (role configured via `vars.AWS_ROLE_ARN`)
- AWS region: us-east-1

## Key difference from ecs-fargate-project
ONE shared ECS cluster for both blue and green services (not two separate clusters).
Blue and green task definitions run on `ecs-online-shop-dev-cluster`.

## Module Structure
```
modules/
  vpc/          -- VPC, subnets, IGW, NAT, flow logs
  ecr/          -- container registry (IMMUTABLE tags, scan on push)
  iam/          -- task execution + task roles
  alb/          -- ALB, blue/green TGs, weighted HTTP/HTTPS listener
  ecs_cluster/  -- ECS cluster + capacity providers (FARGATE default)
  ecs_service/  -- task definition, service, SG, log group (takes cluster_name)
```

## Architecture
```
Internet → ALB (port 80, or 443 if certificate_arn is set)
  Weighted forward: blue-tg (100/0) | green-tg (0/100) per active_color

ecs-online-shop-dev-cluster (ONE shared cluster)
  └── ecs-online-shop-dev-blue-service   (Products API v1)
  └── ecs-online-shop-dev-green-service  (Products API v2)
```

## Blue-Green Cutover Sequence
1. Bump standby desired_count to match active (e.g., `green_desired_count = 1`)
2. `terraform apply` — green tasks start, register with TG, pass health checks
3. Flip `active_color = "green"` — ALB shifts 100% traffic to green
4. Smoke test green: `curl <alb_dns>/products`
5. Scale down old active: `blue_desired_count = 0`
6. `terraform apply`

## GitHub Actions (plan.yml)
- Triggers on PRs to main
- Runs fmt check, validate, plan
- Posts plan output as a collapsible PR comment (updates on re-push)
- Required repo variables: `AWS_ROLE_ARN`, `AWS_REGION`

## Apply Sequence (first time)
1. `create_ecr = true`, all others `false` → `terraform apply` — creates ECR only
2. Build and push first image: `docker build && docker push <ecr_url>:latest`
3. All toggles `true` → `terraform apply`

## Working Preferences
- Modular, DRY. Flag security risks immediately.
- Minimum code. Touch only what you must.
- Inline comments on non-obvious logic only.
- YAML over JSON where both are valid.
