variable "service_name" {
  type        = string
  nullable    = false
  description = "The name of the service"
}

variable "cluster_name" {
  type        = string
  nullable    = false
  description = "The name of the cluster"
}

variable "example_service_port" {
  type        = number
  nullable    = false
  description = "The port of the example service"
}

variable "example_service_docker_image" {
  type        = string
  nullable    = false
  description = "The docker image of the example service"
}

variable "alb_name" {
  type        = string
  nullable    = false
  description = "The name of the alb"
}

variable "alb_security_group_id" {
  type        = string
  nullable    = false
  description = "The security group id of the alb"
}

variable "alb_target_group_arn" {
  type        = string
  nullable    = false
  description = "The arn of the blue target group"
}

variable "alb_http_listener_arn" {
  type        = string
  nullable    = false
  description = "The arn of the http listener"
}

variable "public_subnets" {
  type        = list(string)
  nullable    = false
  description = "List of public subnets to deploy ecs services to"
}

variable "region" {
  type        = string
  nullable    = false
  description = "The region to deploy to"
}
