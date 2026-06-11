module "ipp" {
  source = "github.com/ggozain/ipp?ref=v1.0.0"

  service_short_code = "ipp"
  tag_environment    = "dev"
  tag_cost_center    = "platform"

  # The map takes one entry per function. Each gets its own SQS source queue,
  # DLQ, Lambda, log group and the three CloudWatch alarms.
  lambda_functions = {
    event-processor = {
      name      = "event-processor"
      image_uri = "111122223333.dkr.ecr.eu-central-1.amazonaws.com/ipp/event-processor:1.0.0"

      environment_variables = {
        LOG_LEVEL = "INFO"
      }
    }

    event-archiver = {
      name      = "event-archiver"
      image_uri = "111122223333.dkr.ecr.eu-central-1.amazonaws.com/ipp/event-archiver:1.0.0"

      environment_variables = {
        LOG_LEVEL = "INFO"
      }
    }
  }
}
