variable "alb_name" {
  type        = string
  description = "The name of the ALB"
}

variable "public_subnets" {
  type        = list(string)
  description = "List of public subnets to deploy ecs services to"
}
