data "aws_region" "current" {}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/../example-lambda/build/index.mjs"
  output_path = "lambda_function.zip"
}

resource "aws_lambda_function" "lambda" {
  function_name    = "${local.service_name}-consumer"
  role             = aws_iam_role.lambda.arn
  runtime          = "nodejs20.x"
  handler          = "index.handler"
  memory_size      = 128
  timeout          = 65
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
  architectures    = ["arm64"]

  environment {
    variables = {
      SERVICE_BASE_URL = "http://${aws_lb.alb.dns_name}"
    }
  }
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name                = "${local.service_name}-lambda"
  assume_role_policy  = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "lambda" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_allow_lambda_execution" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda_allow_lambda_execution.arn
}

resource "aws_iam_policy" "lambda_allow_lambda_execution" {
  name   = "${local.service_name}-lambda-allow-lambda-execution"
  policy = data.aws_iam_policy_document.lambda_allow_lambda_execution.json
}

data "aws_iam_policy_document" "lambda_allow_lambda_execution" {
  statement {
    effect  = "Allow"
    actions = ["lambda:InvokeFunction"]
    resources = [
      aws_lambda_function.lambda.arn
    ]
  }
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${aws_lambda_function.lambda.function_name}"
  retention_in_days = 3
}

# trigger the lambda function every minute with a specific input
resource "aws_cloudwatch_event_rule" "lambda" {
  name                = "${local.service_name}-lambda-trigger"
  schedule_expression = "rate(1 minute)"
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.lambda.name
  target_id = "lambda"
  arn       = aws_lambda_function.lambda.arn

  input = <<JSON
{
  "body": {
    "task": "trigger",
    "lambdaArn": "arn:aws:lambda:eu-central-1:440023649505:function:prod-ecs-codedeploy-example-service-consumer",
    "invocations": 60,
    "waitTimeBetweenInvocations": 1000
  }
}
JSON
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda.arn
}

