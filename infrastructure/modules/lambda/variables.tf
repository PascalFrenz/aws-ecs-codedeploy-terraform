variable "service_name" {
  type        = string
  nullable    = false
  description = "The name of the service"
}

variable "service_base_url" {
  type        = string
  nullable    = false
  description = "The base url of the service"
}

variable "enable_lambda_consumer" {
  type        = bool
  nullable    = true
  description = "Whether or not the lambda consumer should automatically make requests to the example service"
}
