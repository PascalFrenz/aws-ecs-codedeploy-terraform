resource "aws_appconfig_application" "appconfig" {
  name = local.appconfig_name
  description = "Contains the configuration for the ${local.application_name} application"
}

resource "aws_appconfig_configuration_profile" "health_check" {
  application_id = aws_appconfig_application.appconfig.id
  location_uri = "hosted"
  type = "AWS.AppConfig.FeatureFlags"
  name = "Health Check"
  description = "Configures the health check endpoint of the application."
}

resource "aws_appconfig_environment" "production" {
  application_id = aws_appconfig_application.appconfig.id
  name = "Production"
  description = "The production environment for the ${local.application_name} application"
}

resource "aws_appconfig_hosted_configuration_version" "health_check" {
  application_id = aws_appconfig_application.appconfig.id
  configuration_profile_id = aws_appconfig_configuration_profile.health_check.configuration_profile_id
  content_type = "application/json"

  content = jsonencode({
    flags: {
      isHealthy: {
        name: "IsHealthy"
        description: "Determines whether the applications /health endpoint should be healthy or not."
      }
    },
    values: {
      isHealthy: {
        enabled: "false"
      }
    },
    version: "1"
  })

  lifecycle {
    # Create the feature flag initially and then ignore changes to it.
    ignore_changes = [content]
  }
}
