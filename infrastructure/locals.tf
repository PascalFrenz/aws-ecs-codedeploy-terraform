locals {
  application_name = "ecs-codedeploy-example"
  service_name     = "${var.stage}-${local.application_name}-service"
  cluster_name     = "${var.stage}-${local.application_name}"
  alb_name         = "${var.stage}-${local.application_name}"
  codedeploy_name  = "${var.stage}-${local.application_name}"

  example_service_docker_image = "ghcr.io/pascalfrenz/aws-ecs-codedeploy-terraform/webserver:latest"
  example_service_port         = 8080
}
