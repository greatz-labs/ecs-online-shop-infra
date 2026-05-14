data "aws_region" "current" {}

locals {
  name_prefix    = "${var.project_name}-${var.environment}-${var.slot}"
  container_name = "${var.project_name}-${var.slot}"

  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

# ── CloudWatch log group ───────────────────────────────────────────────────────
# Must exist before tasks start — awslogs driver won't auto-create it.

resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${local.name_prefix}"
  retention_in_days = var.log_retention_days

  tags = merge(local.common_tags, { Name = "/ecs/${local.name_prefix}" })
}

# ── Task definition ───────────────────────────────────────────────────────────

resource "aws_ecs_task_definition" "this" {
  family                   = "${local.name_prefix}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = local.container_name
      image     = "${var.ecr_repository_url}:${var.image_tag}"
      essential = true

      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]

      # Prevents malware from writing to the container filesystem.
      # Set PYTHONDONTWRITEBYTECODE=1 in environment_variables.
      readonlyRootFilesystem = true
      privileged             = false

      linuxParameters = {
        capabilities = { drop = ["ALL"] }
        # tmpfs gives a writable /tmp without exposing the root FS.
        tmpfs = [
          {
            containerPath = "/tmp"
            size          = 64
            mountOptions  = ["rw", "noexec", "nosuid"]
          }
        ]
      }

      environment = [
        for k, v in var.environment_variables : { name = k, value = v }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.this.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -sf http://localhost:${var.container_port}${var.health_check_path} || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-task" })
}

# ── Task security group ───────────────────────────────────────────────────────
# Inbound restricted to ALB SG only; egress open for ECR, CloudWatch.

resource "aws_security_group" "task" {
  name        = "${local.name_prefix}-task-sg"
  description = "ECS tasks: inbound from ALB SG only on container port"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.alb_security_group_id != "" ? [1] : []
    content {
      description     = "From ALB on container port"
      from_port       = var.container_port
      to_port         = var.container_port
      protocol        = "tcp"
      security_groups = [var.alb_security_group_id]
    }
  }

  egress {
    description = "Outbound for ECR pulls and CloudWatch"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-task-sg" })

  lifecycle {
    create_before_destroy = true
  }
}

# ── ECS Service ───────────────────────────────────────────────────────────────

resource "aws_ecs_service" "this" {
  name            = "${local.name_prefix}-service"
  cluster         = var.cluster_name
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.task.id]
    assign_public_ip = false
  }

  dynamic "load_balancer" {
    for_each = var.target_group_arn != "" ? [1] : []
    content {
      target_group_arn = var.target_group_arn
      container_name   = local.container_name
      container_port   = var.container_port
    }
  }

  health_check_grace_period_seconds = var.target_group_arn != "" ? var.health_check_grace_period : 0

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  # CI/CD updates task_definition directly; Terraform owns desired_count.
  lifecycle {
    ignore_changes = [task_definition]
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-service" })
}
