terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ---------------------------------------------------------------------------
# Données existantes (Academy : on ne crée PAS de rôle IAM)
# ---------------------------------------------------------------------------

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# LabRole est imposé par AWS Academy comme execution role ET task role
data "aws_iam_role" "lab" {
  name = "LabRole"
}

# ---------------------------------------------------------------------------
# Registre d'images
# ---------------------------------------------------------------------------

resource "aws_ecr_repository" "app" {
  name = var.app_name

  # IMMUTABLE : un tag déjà poussé ne peut plus être écrasé.
  # Argument de sécurité pour le rapport : garantit qu'une image auditée
  # reste bien celle qui tourne en production.
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  # Permet le "terraform destroy" complet lors des tests from scratch
  force_delete = true

  tags = var.tags
}

# ---------------------------------------------------------------------------
# Réseau : deux Security Groups, ALB public / tâches privées
# ---------------------------------------------------------------------------

resource "aws_security_group" "alb" {
  name        = "${var.app_name}-alb-sg"
  description = "Entree HTTP publique vers l'ALB"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "aws_security_group" "tasks" {
  name        = "${var.app_name}-tasks-sg"
  description = "Tâches Fargate joignables uniquement depuis l'ALB"
  vpc_id      = data.aws_vpc.default.id

  # Moindre privilège : pas de 0.0.0.0/0 ici, seulement le SG de l'ALB
  ingress {
    description     = "Depuis l'ALB uniquement"
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

# ---------------------------------------------------------------------------
# Load balancer
# ---------------------------------------------------------------------------

resource "aws_lb" "app" {
  name               = "${var.app_name}-alb"
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default.ids
  security_groups    = [aws_security_group.alb.id]

  tags = var.tags
}

resource "aws_lb_target_group" "app" {
  name        = "${var.app_name}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "ip" # obligatoire avec le mode réseau awsvpc de Fargate

  # Sonde de santé : c'est elle qui déclenche l'auto-réparation
  health_check {
    path                = var.health_check_path
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  deregistration_delay = 30

  tags = var.tags
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# ---------------------------------------------------------------------------
# Cluster, logs, task definition
# ---------------------------------------------------------------------------

resource "aws_ecs_cluster" "this" {
  name = "${var.app_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "disabled" # payant, inutile en Academy
  }

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${var.app_name}"
  retention_in_days = 1

  tags = var.tags
}

resource "aws_ecs_task_definition" "app" {
  family                   = var.app_name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory

  # Academy : on réutilise LabRole, on n'en crée pas
  execution_role_arn = data.aws_iam_role.lab.arn
  task_role_arn      = data.aws_iam_role.lab.arn

  container_definitions = jsonencode([
    {
      name      = var.app_name
      image     = "${aws_ecr_repository.app.repository_url}:${var.image_tag}"
      essential = true

      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.app.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = var.tags
}

# ---------------------------------------------------------------------------
# Service
# ---------------------------------------------------------------------------

resource "aws_ecs_service" "app" {
  name            = "${var.app_name}-svc"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  # Le scheduler ECS relance automatiquement toute tâche qui meurt
  # ou que l'ALB déclare unhealthy : c'est l'auto-réparation à démontrer.
  health_check_grace_period_seconds = 30

  network_configuration {
    subnets         = data.aws_subnets.default.ids
    security_groups = [aws_security_group.tasks.id]

    # Nécessaire dans les subnets publics du VPC par défaut :
    # sans NAT Gateway, c'est le seul moyen de tirer l'image depuis ECR.
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = var.app_name
    container_port   = var.container_port
  }

  depends_on = [aws_lb_listener.http]

  tags = var.tags
}
