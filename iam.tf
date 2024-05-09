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
