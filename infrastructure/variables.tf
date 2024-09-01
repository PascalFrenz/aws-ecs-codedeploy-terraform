variable "stage" {
  type        = string
  nullable    = false
  description = "The stage to deploy to"
}

variable "region" {
  type        = string
  nullable    = false
  description = "The region to deploy to"
}

variable "public_subnets" {
  type        = list(string)
  nullable    = false
  description = "List of public subnets to deploy ecs services to"
}

variable "vpc_id" {
  type        = string
  nullable    = false
  description = "The VPC ID to deploy resources to"
}

variable "aws_profile" {
  type        = string
  nullable    = true
  description = "The AWS profile to use to access the AWS API"
}

variable "enable_lambda_consumer" {
  type        = bool
  nullable    = true
  description = "Whether or not the lambda consumer should automatically make requests to the example service"
}
