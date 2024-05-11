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

resource "aws_iam_role" "service_execution_role" {
  name                = "${local.service_name}-execution-role"
  assume_role_policy  = data.aws_iam_policy_document.service_assume_role.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"]
}

resource "aws_iam_role_policy_attachment" "service_appconfig_permissions" {
  role       = aws_iam_role.service_execution_role.name
  policy_arn = aws_iam_policy.appconfig_permissions.arn
}

resource "aws_iam_policy" "appconfig_permissions" {
  name        = "${local.service_name}-appconfig-permissions"
  description = "Allows the service to read configurations from AppConfig"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "appconfig:StartConfigurationSession",
          "appconfig:GetLatestConfiguration"
        ],
        // todo: restrict to the appconfig app
        Resource = "*"
      }
    ]
  })
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
