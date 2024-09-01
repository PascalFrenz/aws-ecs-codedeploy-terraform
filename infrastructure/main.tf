# ------------------------------------------------------------------------------
#
# CodeDeploy Resources
#
# ------------------------------------------------------------------------------
resource "aws_codedeploy_app" "app" {
  name             = local.codedeploy_name
  compute_platform = "ECS"
}

resource "aws_codedeploy_deployment_group" "app" {
  app_name               = aws_codedeploy_app.app.name
  deployment_group_name  = local.codedeploy_name
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  service_role_arn       = aws_iam_role.codedeploy_service_role.arn

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.cluster.name
    service_name = aws_ecs_service.service.name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_lb_listener.production.arn]
      }
      target_group {
        name = aws_lb_target_group.blue.name
      }

      target_group {
        name = aws_lb_target_group.green.name
      }
    }
  }
}

# ------------------------------------------------------------------------------
#
# Load Balancer
#
# ------------------------------------------------------------------------------
resource "aws_lb" "alb" {
  name               = local.alb_name
  internal           = false
  load_balancer_type = "application"
  subnets            = var.public_subnets
  security_groups    = [aws_security_group.lb.id]
}

resource "aws_lb_target_group" "blue" {
  name                               = "${local.alb_name}-b"
  port                               = local.example_service_port
  protocol                           = "HTTP"
  target_type                        = "ip"
  vpc_id                             = var.vpc_id
  lambda_multi_value_headers_enabled = false
  proxy_protocol_v2                  = false

  health_check {
    enabled             = true
    path                = "/health"
    port                = local.example_service_port
    protocol            = "HTTP"
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group" "green" {
  name                               = "${local.alb_name}-g"
  port                               = local.example_service_port
  protocol                           = "HTTP"
  target_type                        = "ip"
  vpc_id                             = var.vpc_id
  lambda_multi_value_headers_enabled = false
  proxy_protocol_v2                  = false

  health_check {
    enabled             = true
    path                = "/health"
    port                = local.example_service_port
    protocol            = "HTTP"
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "production" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "forward"
    forward {
      target_group {
        arn    = aws_lb_target_group.blue.arn
        weight = 100
      }
    }
  }

  lifecycle {
    # ignore changes to the default action target group as it changes when a deployment is triggered via CodeDeploy
    ignore_changes = [default_action.0.forward]
  }
}

# ------------------------------------------------------------------------------
#
# ECS Resources
#
# ------------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "service" {
  name              = "/ecs/${local.service_name}"
  retention_in_days = 7
}

resource "aws_ecs_cluster" "cluster" {
  name = local.cluster_name
}

# we are using spot instances in this example to save on costs
resource "aws_ecs_cluster_capacity_providers" "cluster" {
  cluster_name = aws_ecs_cluster.cluster.name
  capacity_providers = ["FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 100
    base              = 1
  }
}

resource "aws_ecs_service" "service" {
  name            = local.service_name
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
    container_port   = local.example_service_port
    target_group_arn = aws_lb_target_group.blue.arn
  }

  lifecycle {
    ignore_changes = [
      task_definition, # the task definition is changed by the CodeDeploy deployment
      desired_count, # autoscaling might change the desired count, thus it is ignored here
      load_balancer  # the load balancer block is changed by the CodeDeploy deployment
    ]
  }
}

resource "aws_ecs_task_definition" "service" {
  family                   = local.service_name
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
      image          = local.example_service_docker_image
      portMappings = [{
        containerPort = local.example_service_port
        hostPort      = local.example_service_port
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

