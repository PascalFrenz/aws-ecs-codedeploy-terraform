# ------------------------------------------------------------------------------
#
# Shared Resources
#
# ------------------------------------------------------------------------------
module "shared" {
  source         = "./modules/shared"
  alb_name       = local.alb_name
  public_subnets = var.public_subnets
}

# ------------------------------------------------------------------------------
#
# ECS Resources
#
# ------------------------------------------------------------------------------
module "ecs" {
  source       = "./modules/ecs"
  cluster_name = local.cluster_name
  service_name = local.service_name

  example_service_docker_image = local.example_service_docker_image
  example_service_port         = local.example_service_port

  alb_security_group_id = module.shared.alb_security_group_id

  alb_name              = local.alb_name
  alb_target_group_arn  = aws_lb_target_group.blue.arn
  alb_http_listener_arn = module.shared.alb_http_listener_arn
  public_subnets        = var.public_subnets
  region                = var.region
}

# ------------------------------------------------------------------------------
#
# Lambda Resources
#
# ------------------------------------------------------------------------------
module "lambda" {
  source                 = "./modules/lambda"
  service_name           = local.service_name
  service_base_url       = "http://${module.shared.alb_dns_name}"
  enable_lambda_consumer = var.enable_lambda_consumer
}

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
    cluster_name = module.ecs.cluster_name
    service_name = module.ecs.service_name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [module.shared.alb_http_listener_arn]
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

resource "aws_iam_role" "codedeploy_service_role" {
  name = "${local.codedeploy_name}-service-role"

  assume_role_policy  = data.aws_iam_policy_document.codedeploy_assume_role.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"]
}

data "aws_iam_policy_document" "codedeploy_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codedeploy.amazonaws.com"]
    }
  }
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
