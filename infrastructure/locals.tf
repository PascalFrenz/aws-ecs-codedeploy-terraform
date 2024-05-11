locals {
  application_name = "ecs-codedeploy-example"
  service_name     = "${var.stage}-${local.application_name}-service"
  cluster_name     = "${var.stage}-${local.application_name}"
  alb_name         = "${var.stage}-${local.application_name}"
  codedeploy_name  = "${var.stage}-${local.application_name}"
  appconfig_name   = "${var.stage}-${local.application_name}-configuration"
}
