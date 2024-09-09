resource "aws_cloudwatch_log_group" "service" {
  name              = "/ecs/${var.service_name}"
  retention_in_days = 7
}

resource "aws_ecs_cluster" "cluster" {
  name = var.cluster_name
}

# we are using spot instances in this example to save on costs
resource "aws_ecs_cluster_capacity_providers" "cluster" {
  cluster_name       = aws_ecs_cluster.cluster.name
  capacity_providers = ["FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 100
    base              = 1
  }
}

resource "aws_ecs_service" "service" {
  name            = var.service_name
  cluster         = aws_ecs_cluster.cluster.id
  launch_type     = "FARGATE"
  desired_count   = 1
  task_definition = aws_ecs_task_definition.service.arn

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  network_configuration {
    subnets          = var.public_subnets
    security_groups  = [aws_security_group.service.id]
    assign_public_ip = true
  }

  load_balancer {
    container_name   = "webserver"
    container_port   = var.example_service_port
    target_group_arn = var.alb_target_group_arn
  }

  lifecycle {
    ignore_changes = [
      task_definition, # the task definition is changed by the CodeDeploy deployment
      desired_count,   # autoscaling might change the desired count, thus it is ignored here
      load_balancer    # the load balancer block is changed by the CodeDeploy deployment
    ]
  }
}

resource "aws_ecs_task_definition" "service" {
  family                   = var.service_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.service_execution_role.arn
  container_definitions = jsonencode([
    {
      name           = "webserver"
      cpu            = 256
      memory         = 512
      environment    = []
      mountPoints    = []
      systemControls = []
      volumesFrom    = []
      essential      = true
      image          = var.example_service_docker_image
      portMappings = [{
        containerPort = var.example_service_port
        hostPort      = var.example_service_port
        protocol      = "tcp"
      }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.service.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  runtime_platform {
    operating_system_family = "LINUX"
  }
}

resource "aws_iam_role" "service_execution_role" {
  name                = "${var.service_name}-execution-role"
  assume_role_policy  = data.aws_iam_policy_document.service_assume_role.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"]
}

data "aws_iam_policy_document" "service_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_lb_listener_rule" "service_rule" {
  listener_arn = var.alb_http_listener_arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = var.alb_target_group_arn
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  lifecycle {
    # ignore changes to the default action target group as it changes when a deployment is triggered via CodeDeploy
    ignore_changes = [action.0.target_group_arn]
  }
}
